import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_back_page_header.dart';
import '../../../shared/widgets/app_form_card.dart';
import '../../home/widgets/home_shell_layout.dart';
import '../legal_documents.dart';
import '../widgets/legal_section.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  static const String _lastUpdated =
      'Última atualização: 20 de outubro de 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      extendBodyBehindAppBar: true,
      appBar: const AppBackPageHeader(title: 'Termos e Condições'),
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
                  'Termos e Condições de Uso — JacalorIA',
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
                  'Versão ${LegalDocuments.termsVersion}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const LegalSection(
                  title: '1. Aceitação dos Termos',
                  body:
                      'Estes Termos e Condições de Uso regulam o acesso e a '
                      'utilização do aplicativo JacalorIA. Ao criar uma conta '
                      'ou utilizar o aplicativo, você declara que leu, '
                      'compreendeu e concorda com estes Termos e com a '
                      'Política de Privacidade. Se você não concordar com '
                      'qualquer disposição, não utilize o aplicativo.',
                ),
                LegalSection(
                  title: '2. Elegibilidade',
                  body:
                      'Você deve ter pelo menos ${LegalDocuments.minUserAgeYears} '
                      'anos para criar e usar uma conta no JacalorIA.',
                ),
                const LegalSection(
                  title: '3. Conta e segurança',
                  body:
                      'Você é responsável por manter a confidencialidade de '
                      'suas credenciais e por todas as atividades realizadas '
                      'em sua conta. Informe dados verdadeiros e atualizados.',
                ),
                const LegalSection(
                  title: '4. Descrição do serviço',
                  body:
                      'O JacalorIA oferece ferramentas de acompanhamento de '
                      'alimentação, água, peso, passos (no dispositivo), '
                      'treinos, missões e recursos sociais. Estimativas '
                      'nutricionais geradas por inteligência artificial são '
                      'aproximações e não substituem orientação profissional '
                      'de saúde.',
                ),
                const LegalSection(
                  title: '5. Dados pessoais e onboarding',
                  body:
                      'Dados fornecidos no cadastro e no onboarding (como data '
                      'de nascimento, peso, altura, sexo, objetivo e nível de '
                      'atividade) devem ser verdadeiros e atualizados, pois '
                      'são utilizados para calcular suas metas. O tratamento '
                      'detalhado está na Política de Privacidade.',
                ),
                const LegalSection(
                  title: '6. Dados coletados e privacidade',
                  body:
                      'Coletamos e tratamos dados de conta, perfil, conteúdo '
                      'enviado por você (incluindo fotos de refeições), dados '
                      'sociais, gamificação e, se não desativado, analytics '
                      'próprio. Fotos e descrições de refeições podem ser '
                      'processadas por serviços de IA de terceiros '
                      '(Google Gemini) para gerar estimativas. O tratamento '
                      'observa a Lei nº 13.709/2018 (LGPD). Você pode baixar '
                      'seus dados, ajustar privacidade do perfil, desativar '
                      'analytics e excluir a conta pelo aplicativo, ou '
                      'solicitar direitos via Suporte (Privacidade / LGPD).',
                ),
                const LegalSection(
                  title: '7. Moeda virtual e itens do aplicativo',
                  body:
                      'O JacalorIA possui uma moeda virtual ("ouro") obtida '
                      'por meio do uso do aplicativo, que pode ser trocada por '
                      'itens cosméticos e funcionalidades internas. O ouro e '
                      'os itens adquiridos não possuem valor monetário real, '
                      'não são reembolsáveis, não podem ser transferidos ou '
                      'trocados por dinheiro e podem ser ajustados, alterados '
                      'ou descontinuados a critério do JacalorIA.',
                ),
                const LegalSection(
                  title: '8. Recursos sociais e conduta do usuário',
                  body:
                      'Ao utilizar os recursos sociais (amigos, grupos e '
                      'rankings), você se compromete a não publicar conteúdo '
                      'ofensivo, ilegal, discriminatório ou que viole direitos '
                      'de terceiros, e a não utilizar o aplicativo para '
                      'assediar outros usuários. Também é proibido tentar '
                      'burlar os sistemas do aplicativo, explorar falhas, '
                      'automatizar interações ou manipular missões, rankings '
                      'e recompensas. O descumprimento destas regras pode '
                      'resultar em suspensão ou exclusão da conta.',
                ),
                const LegalSection(
                  title: '9. Propriedade intelectual',
                  body:
                      'O aplicativo JacalorIA, incluindo sua marca, logotipo, '
                      'design, textos, ilustrações e código, é protegido por '
                      'direitos de propriedade intelectual e não pode ser '
                      'copiado, modificado ou distribuído sem autorização. O '
                      'conteúdo que você envia (como fotos de refeições) '
                      'continua sendo seu; você nos concede apenas a licença '
                      'necessária para processá-lo e exibi-lo dentro do '
                      'aplicativo.',
                ),
                const LegalSection(
                  title: '10. Limitação de responsabilidade',
                  body:
                      'O JacalorIA é fornecido "como está". Empregamos '
                      'esforços razoáveis para manter o serviço disponível e '
                      'preciso, mas não garantimos funcionamento ininterrupto, '
                      'livre de erros ou exatidão das estimativas geradas por '
                      'inteligência artificial. Na máxima extensão permitida '
                      'pela lei, o JacalorIA não se responsabiliza por '
                      'decisões de saúde ou alimentação tomadas com base nas '
                      'informações do aplicativo, nem por danos indiretos '
                      'decorrentes do uso ou da indisponibilidade do serviço.',
                ),
                const LegalSection(
                  title: '11. Encerramento de conta',
                  body:
                      'Você pode excluir sua conta a qualquer momento pelo '
                      'perfil do aplicativo. Também pode solicitar exclusão '
                      'pelo Suporte. Podemos suspender ou encerrar contas que '
                      'violem estes Termos, mediante análise do caso.',
                ),
                const LegalSection(
                  title: '12. Alterações destes Termos',
                  body:
                      'Estes Termos podem ser atualizados periodicamente para '
                      'refletir mudanças no aplicativo ou na legislação. A '
                      'versão vigente estará sempre disponível no aplicativo, '
                      'com a data da última atualização. O uso continuado do '
                      'JacalorIA após alterações materiais significa '
                      'concordância com a nova versão.',
                ),
                const LegalSection(
                  title: '13. Contato',
                  body:
                      'Em caso de dúvidas sobre estes Termos, sobre o '
                      'tratamento de seus dados ou para exercer direitos da '
                      'LGPD, utilize o canal "Suporte" disponível no '
                      'aplicativo (assunto Privacidade / LGPD quando '
                      'cabível).',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
