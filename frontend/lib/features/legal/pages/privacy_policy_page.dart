import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_back_page_header.dart';
import '../../../shared/widgets/app_form_card.dart';
import '../../home/widgets/home_shell_layout.dart';
import '../legal_documents.dart';
import '../widgets/legal_section.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const String _lastUpdated =
      'Última atualização: 20 de outubro de 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      extendBodyBehindAppBar: true,
      appBar: const AppBackPageHeader(title: 'Política de Privacidade'),
      body: AppBackPageContent(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppBackPageHeader.scrollTopInset(context, extra: AppSpacing.lg),
            AppSpacing.pageHorizontal,
            homeShellScrollBottomInset(context),
          ),
          child: AppFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Política de Privacidade — JacalorIA',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _lastUpdated,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Versão ${LegalDocuments.privacyVersion}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const LegalSection(
                  title: '1. Quem somos e encarregado',
                  body:
                      'O JacalorIA é um aplicativo de acompanhamento nutricional, '
                      'hábitos e treinos. Para dúvidas sobre privacidade, '
                      'exercício de direitos ou exclusão de dados, utilize o '
                      'canal Suporte do aplicativo com o assunto '
                      '"Privacidade / LGPD". Esse canal funciona como contato '
                      'do encarregado pelo tratamento de dados pessoais.',
                ),
                const LegalSection(
                  title: '2. Quais dados tratamos',
                  body:
                      'Conta: nome, e-mail e credenciais (senha armazenada de '
                      'forma criptografada; ou autenticação via Google). '
                      'Perfil: data de nascimento, peso, altura, sexo, objetivo, '
                      'nível de atividade, metas nutricionais e avatar. '
                      'Conteúdo: refeições (incluindo fotos e descrições), '
                      'água, peso ao longo do tempo, treinos, grupos e '
                      'mensagens em grupos. Uso: eventos de analytics do '
                      'próprio app (quando você não desativa), suporte e '
                      'dados de gamificação (missões, moedas virtuais). '
                      'Passos e dados do Health Connect / sensores do aparelho '
                      'permanecem no dispositivo e não são enviados ao nosso '
                      'servidor.',
                ),
                const LegalSection(
                  title: '3. Dados sensíveis de saúde',
                  body:
                      'Informações de peso, altura, alimentação, objetivos e '
                      'fotos de refeições são tratadas como dados relacionados '
                      'à saúde. Elas são usadas para calcular metas, registrar '
                      'seu histórico e gerar estimativas nutricionais. O '
                      'tratamento ocorre para prestação do serviço que você '
                      'solicitou ao criar a conta e usar o aplicativo.',
                ),
                const LegalSection(
                  title: '4. Bases legais (LGPD)',
                  body:
                      'Execução de contrato / procedimentos preliminares '
                      '(art. 7º, V): criar e manter sua conta, onboarding, '
                      'metas, refeições, treinos e recursos sociais. '
                      'Cumprimento de obrigação legal (art. 7º, II): quando '
                      'aplicável. Legítimo interesse (art. 7º, IX): melhorar '
                      'o produto com analytics próprio, sempre com opção de '
                      'desativação. Consentimento (art. 7º, I e art. 11): '
                      'quando você envia fotos/descrições para análise por IA '
                      'e ao aceitar esta Política e os Termos ao se cadastrar '
                      'ou continuar usando o app após atualizações materiais.',
                ),
                const LegalSection(
                  title: '5. Finalidades',
                  body:
                      'Prestar o serviço JacalorIA; autenticar usuários; '
                      'calcular e exibir metas; analisar refeições com IA; '
                      'oferecer recursos sociais e gamificação; responder '
                      'suporte; melhorar estabilidade e experiência; cumprir '
                      'direitos do titular e obrigações legais.',
                ),
                const LegalSection(
                  title: '6. Terceiros e transferência internacional',
                  body:
                      'Google Sign-In: autenticação (Google LLC). '
                      'Google Gemini: análise de fotos/descrições de refeições '
                      'e importação assistida de treinos, apenas para gerar '
                      'estimativas. Infraestrutura de nuvem e e-mail podem '
                      'envolver provedores fora do Brasil. Nesses casos, '
                      'adotamos medidas contratuais e técnicas adequadas. '
                      'Não vendemos seus dados pessoais.',
                ),
                const LegalSection(
                  title: '7. Retenção',
                  body:
                      'Mantemos seus dados enquanto a conta existir e for '
                      'necessária à prestação do serviço. Após exclusão da '
                      'conta, apagamos ou anonimizamos os dados pessoais em '
                      'prazo razoável, salvo retenção mínima exigida por lei '
                      '(por exemplo, registros anonimizados de suporte). '
                      'Códigos de verificação/redefinição expiram em minutos. '
                      'Eventos de analytics vinculados à conta são removidos '
                      'na exclusão.',
                ),
                const LegalSection(
                  title: '8. Seus direitos',
                  body:
                      'Nos termos da LGPD, você pode solicitar: confirmação '
                      'de tratamento; acesso; correção; anonimização, bloqueio '
                      'ou eliminação; portabilidade; informação sobre '
                      'compartilhamentos; revogação de consentimento; e '
                      'oposição a tratamentos desnecessários. No app: editar '
                      'perfil; baixar seus dados; excluir a conta; desativar '
                      'analytics; controlar o que aparece no perfil público; '
                      'e abrir Suporte (Privacidade / LGPD).',
                ),
                const LegalSection(
                  title: '9. Segurança',
                  body:
                      'Usamos autenticação por token, hash de senha, controle '
                      'de acesso por usuário e comunicação criptografada (HTTPS) '
                      'em produção. Nenhum sistema é 100% livre de riscos; '
                      'em caso de incidente relevante, seguiremos os deveres '
                      'legais de comunicação.',
                ),
                LegalSection(
                  title: '10. Menores de idade',
                  body:
                      'O JacalorIA é destinado a pessoas com '
                      '${LegalDocuments.minUserAgeYears} anos ou mais. Não '
                      'coletamos intencionalmente dados de menores abaixo '
                      'dessa idade. Contas em desacordo poderão ser encerradas.',
                ),
                const LegalSection(
                  title: '11. Cookies e web',
                  body:
                      'Na versão web, usamos armazenamento local necessário ao '
                      'login e à sessão. Não utilizamos redes de anúncios de '
                      'terceiros. Analytics próprio pode ser desativado em '
                      'Editar dados pessoais.',
                ),
                const LegalSection(
                  title: '12. Alterações',
                  body:
                      'Podemos atualizar esta Política. A versão vigente e a '
                      'data de atualização ficam disponíveis no aplicativo. '
                      'Mudanças materiais serão refletidas na versão do '
                      'documento registrada no aceite da conta.',
                ),
                const LegalSection(
                  title: '13. Contato',
                  body:
                      'Dúvidas, pedidos de acesso, correção, portabilidade ou '
                      'exclusão: canal Suporte do aplicativo, assunto '
                      '"Privacidade / LGPD".',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
