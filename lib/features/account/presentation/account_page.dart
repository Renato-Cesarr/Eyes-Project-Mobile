import 'dart:async';

import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/core/accessibility/accessible_feedback_service.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountTitle)),
      body: SafeArea(
        child: state.when(
          data: (value) => _buildContent(context, value),
          error: (error, stackTrace) => _AccountLoadError(
            onRetry: () => ref.invalidate(accountControllerProvider),
          ),
          loading: () => Center(
            child: Semantics(
              liveRegion: true,
              label: l10n.accountLoading,
              child: const CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AccountState state) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(accountControllerProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    state.isSignedIn
                        ? l10n.accountConnectedHeading
                        : l10n.accountOptionalHeading,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.accountOfflineGuarantee,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (state.failure case final failure?) ...<Widget>[
                  const SizedBox(height: 20),
                  AccessibleRecoveryPanel(
                    announcementKey: failure.kind,
                    title: RecoveryContentResolver.resolve(
                      l10n,
                      failure.kind,
                    ).title,
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
                  const SizedBox(height: 20),
                  Semantics(
                    liveRegion: true,
                    container: true,
                    child: Text(
                      notice,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (state.session case final session?)
                  _ConnectedAccount(
                    userName: session.user.name,
                    userEmail: session.user.email,
                    syncConsent: state.syncConsent,
                    isSubmitting: state.isSubmitting,
                    onConsentChanged: (enabled) =>
                        _changeConsent(context, enabled),
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
                            onFieldSubmitted: (_) =>
                                _passwordFocus.requestFocus(),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            enabled: !state.isSubmitting,
                            autofillHints: const <String>[
                              AutofillHints.password,
                            ],
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
                                        () => _obscurePassword =
                                            !_obscurePassword,
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
                          const SizedBox(height: 24),
                          Semantics(
                            button: true,
                            enabled: !state.isSubmitting,
                            label: state.isSubmitting
                                ? l10n.accountSigningIn
                                : l10n.accountSignIn,
                            excludeSemantics: true,
                            child: FilledButton.icon(
                              onPressed: state.isSubmitting
                                  ? null
                                  : () => _submit(state),
                              icon: ExcludeSemantics(
                                child: state.isSubmitting
                                    ? const SizedBox.square(
                                        dimension: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.login_outlined),
                              ),
                              label: Text(
                                state.isSubmitting
                                    ? l10n.accountSigningIn
                                    : l10n.accountSignIn,
                              ),
                            ),
                          ),
                          if (state.failure == null) ...<Widget>[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: state.isSubmitting
                                  ? null
                                  : _continueOffline,
                              icon: const ExcludeSemantics(
                                child: Icon(Icons.offline_bolt_outlined),
                              ),
                              label: Text(l10n.accountContinueOffline),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
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
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.syncConsentDialogTitle),
          content: Text(l10n.syncConsentDialogMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.syncConsentConfirm),
            ),
          ],
        ),
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(userName, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(userEmail),
              ],
            ),
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
        OutlinedButton.icon(
          onPressed: isSubmitting ? null : onSignOut,
          icon: const ExcludeSemantics(child: Icon(Icons.logout_outlined)),
          label: Text(l10n.accountSignOut),
        ),
      ],
    );
  }
}

final class _AccountLoadError extends StatelessWidget {
  const _AccountLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(l10n.accountLoadError, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: Text(l10n.tryAgain)),
            ],
          ),
        ),
      ),
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
