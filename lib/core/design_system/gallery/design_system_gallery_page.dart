import 'dart:async';

import 'package:eyes_mobile/core/design_system/eyes_design_system.dart';
import 'package:flutter/material.dart';

final class DesignSystemGalleryPage extends StatelessWidget {
  const DesignSystemGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = context.eyesLayout;
    return EyesPageScaffold(
      title: 'Galeria do Design System',
      maxContentWidth: 880,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const EyesPageHeader(
            title: 'Eyes Design System 1.0',
            description:
                'Catálogo interno para revisar componentes, temas e acessibilidade.',
            leading: EyesBrandMark(size: 64, semanticLabel: 'Marca Eyes'),
          ),
          SizedBox(height: layout.spaceXxl),
          const _SectionTitle('Tipografia'),
          SizedBox(height: layout.spaceMd),
          Text(
            'Headline com Lexend',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: layout.spaceSm),
          Text(
            'Texto de leitura com Atkinson Hyperlegible. Caracteres distintos: 1, l, I, 0, O.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: layout.spaceXxl),
          const _SectionTitle('Ações'),
          SizedBox(height: layout.spaceMd),
          Wrap(
            spacing: layout.spaceMd,
            runSpacing: layout.spaceMd,
            children: <Widget>[
              EyesButton(label: 'Ação principal', onPressed: () {}),
              EyesButton(
                label: 'Ação secundária',
                onPressed: () {},
                variant: EyesButtonVariant.outlined,
              ),
              EyesButton(
                label: 'Ação de texto',
                onPressed: () {},
                variant: EyesButtonVariant.text,
              ),
              const EyesButton(
                label: 'Processando',
                onPressed: null,
                loading: true,
              ),
            ],
          ),
          SizedBox(height: layout.spaceXxl),
          const _SectionTitle('Status'),
          SizedBox(height: layout.spaceMd),
          const EyesStatusBanner(
            title: 'Informação',
            message: 'A varredura continua funcionando sem conexão.',
          ),
          SizedBox(height: layout.spaceMd),
          const EyesStatusBanner(
            title: 'Pronto',
            message: 'Câmera e inteligência artificial disponíveis.',
            tone: EyesStatusTone.success,
          ),
          SizedBox(height: layout.spaceMd),
          const EyesStatusBanner(
            title: 'Atenção',
            message: 'Os avisos por voz estão indisponíveis.',
            tone: EyesStatusTone.warning,
          ),
          SizedBox(height: layout.spaceMd),
          const EyesStatusBanner(
            title: 'Falha',
            message: 'Não foi possível iniciar a câmera.',
            tone: EyesStatusTone.error,
          ),
          SizedBox(height: layout.spaceXxl),
          const _SectionTitle('Superfície'),
          SizedBox(height: layout.spaceMd),
          const EyesCard(
            semanticLabel: 'Exemplo de cartão informativo',
            child: Text(
              'Cards agrupam conteúdo relacionado e não substituem toda a estrutura da tela.',
            ),
          ),
          SizedBox(height: layout.spaceXxl),
          const _SectionTitle('Estados de página'),
          SizedBox(height: layout.spaceMd),
          EyesCard(
            child: EyesStateView.empty(
              title: 'Nenhum item encontrado',
              message: 'Ajuste os filtros ou tente novamente mais tarde.',
              actionLabel: 'Limpar filtros',
              onAction: () {},
            ),
          ),
          SizedBox(height: layout.spaceXl),
          EyesButton(
            label: 'Abrir diálogo de confirmação',
            onPressed: () => unawaited(
              EyesConfirmationDialog.show(
                context,
                title: 'Pausar varredura?',
                message:
                    'Os avisos de objetos serão interrompidos até você continuar.',
                confirmLabel: 'Pausar',
                cancelLabel: 'Continuar varredura',
              ),
            ),
            variant: EyesButtonVariant.outlined,
          ),
        ],
      ),
    );
  }
}

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}
