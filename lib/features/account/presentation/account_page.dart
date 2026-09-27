import 'dart:async';

import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/core/accessibility/accessible_feedback_service.dart';
import 'package:eyes_mobile/core/design_system/eyes_design_system.dart';
import 'package:eyes_mobile/core/recovery/accessible_recovery_panel.dart';
import 'package:eyes_mobile/core/recovery/recovery_content.dart';
import 'package:eyes_mobile/features/account/application/account_controller.dart';
import 'package:eyes_mobile/features/account/application/account_state.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({this.returnToOnboarding = false, super.key});

  final bool returnToOnboarding;

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

final class _AccountPageState extends ConsumerState<AccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode(debugLabel: 'account-password');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AccountState>>(accountControllerProvider, (
      previous,
      next,
    ) {
      final previousData = previous?.asData?.value;
      final nextData = next.asData?.value;
      if (nextData == null) {
        return;
      }
      if (nextData.failure != null &&
          nextData.failure != previousData?.failure) {
        unawaited(ref.read(accessibleFeedbackServiceProvider).warn());
      } else if (nextData.notice != AccountNotice.none &&
          nextData.notice != previousData?.notice) {
        unawaited(ref.read(accessibleFeedbackServiceProvider).confirm());
      }
    });
    final state = ref.watch(accountControllerProvider);
    final l10n = AppLocalizations.of(context);
    return EyesPageScaffold(
      title: l10n.appName,
      maxContentWidth: context.eyesLayout.readingMaxWidth,
      child: state.when(
        data: (value) => _buildContent(context, value),
        error: (error, stackTrace) => EyesStateView.error(
          title: l10n.accountLoadError,
          actionLabel: l10n.tryAgain,
          onAction: () => ref.invalidate(accountControllerProvider),
        ),
        loading: () => EyesStateView.loading(title: l10n.accountLoading),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AccountState state) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(accountControllerProvider.notifier);
    final layout = context.eyesLayout;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        EyesPageHeader(
          title: state.isSignedIn
              ? l10n.accountConnectedHeading
              : l10n.accountOptionalHeading,
          description: l10n.accountOfflineGuarantee,
          leading: const ExcludeSemantics(
            child: Icon(Icons.account_circle_outlined, size: 44),
          ),
        ),
        if (state.failure case final failure?) ...<Widget>[
          SizedBox(height: layout.spaceXl),
          AccessibleRecoveryPanel(
            announcementKey: failure.kind,
            title: RecoveryContentResolver.resolve(l10n, failure.kind).title,
            message: RecoveryContentResolver.resolve(
              l10n,
              failure.kind,
            ).message,
            primaryActionLabel: l10n.accountReviewAndRetry,
            onPrimaryAction: controller.clearMessage,
            secondaryActionLabel: l10n.accountContinueOffline,
            onSecondaryAction: _continueOffline,
            blocking: false,
          ),
        ],
        if (_noticeText(l10n, state.notice) case final notice?) ...[
          SizedBox(height: layout.spaceXl),
          EyesStatusBanner(
            title: l10n.accountTitle,
            message: notice,
            tone: EyesStatusTone.success,
            liveRegion: true,
          ),
        ],
        SizedBox(height: layout.spaceXl),
        if (state.session case final session?)
          _ConnectedAccount(
            userName: session.user.name,
            userEmail: session.user.email,
            syncConsent: state.syncConsent,
            isSubmitting: state.isSubmitting,
            onConsentChanged: (enabled) => _changeConsent(context, enabled),
            onSignOut: controller.signOut,
          )
        else
          AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: _emailController,
                    enabled: !state.isSubmitting,
                    autofillHints: const <String>[AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: l10n.emailLabel,
                      hintText: l10n.emailHint,
                    ),
                    validator: (value) => _emailError(l10n, value),
                    onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    enabled: !state.isSubmitting,
                    autofillHints: const <String>[AutofillHints.password],
                    obscureText: _obscurePassword,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: l10n.passwordLabel,
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? l10n.showPassword
                            : l10n.hidePassword,
                        onPressed: state.isSubmitting
                            ? null
                            : () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                        icon: ExcludeSemantics(
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? l10n.passwordRequired
                        : null,
                    onFieldSubmitted: (_) => _submit(state),
                  ),
                  SizedBox(height: layout.spaceXl),
                  EyesButton(
                    label: state.isSubmitting
                        ? l10n.accountSigningIn
                        : l10n.accountSignIn,
                    onPressed: state.isSubmitting ? null : () => _submit(state),
                    icon: Icons.login_outlined,
                    loading: state.isSubmitting,
                    expand: true,
                  ),
                  if (state.failure == null) ...<Widget>[
                    SizedBox(height: layout.spaceMd),
                    EyesButton(
                      label: l10n.accountContinueOffline,
                      onPressed: state.isSubmitting ? null : _continueOffline,
                      icon: Icons.offline_bolt_outlined,
                      variant: EyesButtonVariant.outlined,
                      expand: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _submit(AccountState state) {
    if (state.isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    unawaited(
      ref
          .read(accountControllerProvider.notifier)
          .login(
            email: _emailController.text,
            password: _passwordController.text,
          ),
    );
  }

  void _continueOffline() {
    ref.read(accountControllerProvider.notifier).clearMessage();
    if (widget.returnToOnboarding && context.canPop()) {
      context.pop();
      return;
    }
    context.goNamed(AppRoutes.camera);
  }

  Future<void> _changeConsent(BuildContext context, bool enabled) async {
    final l10n = AppLocalizations.of(context);
    if (enabled) {
      final confirmed = await EyesConfirmationDialog.show(
        context,
        title: l10n.syncConsentDialogTitle,
        message: l10n.syncConsentDialogMessage,
        confirmLabel: l10n.syncConsentConfirm,
        cancelLabel: l10n.cancel,
      );
      if (!(confirmed ?? false)) {
        return;
      }
    }
    await ref.read(accountControllerProvider.notifier).setSyncConsent(enabled);
  }
}

final class _ConnectedAccount extends StatelessWidget {
  const _ConnectedAccount({
    required this.userName,
    required this.userEmail,
    required this.syncConsent,
    required this.isSubmitting,
    required this.onConsentChanged,
    required this.onSignOut,
  });

  final String userName;
  final String userEmail;
  final bool syncConsent;
  final bool isSubmitting;
  final ValueChanged<bool> onConsentChanged;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        EyesCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(userName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(userEmail),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.syncConsentLabel),
          subtitle: Text(l10n.syncConsentDescription),
          value: syncConsent,
          onChanged: isSubmitting ? null : onConsentChanged,
        ),
        const SizedBox(height: 8),
        Text(l10n.syncMetadataOnlyNotice),
        const SizedBox(height: 24),
        EyesButton(
          label: l10n.accountSignOut,
          onPressed: isSubmitting ? null : onSignOut,
          icon: Icons.logout_outlined,
          variant: EyesButtonVariant.outlined,
          expand: true,
        ),
      ],
    );
  }
}

String? _emailError(AppLocalizations l10n, String? rawValue) {
  final value = rawValue?.trim() ?? '';
  if (value.isEmpty) {
    return l10n.emailRequired;
  }
  final separator = value.indexOf('@');
  if (separator <= 0 || separator == value.length - 1 || !value.contains('.')) {
    return l10n.emailInvalid;
  }
  return null;
}

String? _noticeText(AppLocalizations l10n, AccountNotice notice) =>
    switch (notice) {
      AccountNotice.none => null,
      AccountNotice.signedIn => l10n.accountSignedIn,
      AccountNotice.signedOut => l10n.accountSignedOut,
      AccountNotice.consentEnabled => l10n.syncConsentEnabled,
      AccountNotice.consentRevoked => l10n.syncConsentRevoked,
    };
