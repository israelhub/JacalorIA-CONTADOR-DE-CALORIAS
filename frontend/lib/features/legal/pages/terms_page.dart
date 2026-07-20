import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  static const String _lastUpdated = 'Última atualização: 20 de julho de 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Termos e Condições',
          style: AppTextStyles.homeSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
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
              const SizedBox(height: AppSpacing.xl),
              const _TermsSection(
                title: '1. Aceitação dos Termos',
                body:
                    'Estes Termos e Condições de Uso regulam o acesso e a '
                    'utilização do aplicativo JacalorIA. Ao criar uma conta '
                    'ou utilizar o aplicativo, você declara que leu, '
                    'compreendeu e concorda com estes Termos. Se você não '
                    'concordar com qualquer disposição, não utilize o '
                    'aplicativo.',
              ),
              const _TermsSection(
                title: '2. Sobre o serviço',
                body:
                    'O JacalorIA é um aplicativo de acompanhamento '
                    'nutricional que permite registrar refeições, estimar '
                    'calorias e macronutrientes com auxílio de inteligência '
                    'artificial, acompanhar metas diárias, participar de '
                    'missões e desafios e interagir com amigos e grupos '
                    'dentro do aplicativo.',
              ),
              const _TermsSection(
                title: '3. Estimativas geradas por inteligência artificial',
                body:
                    'As análises de refeições (por foto ou texto) são '
                    'geradas por inteligência artificial e representam '
                    'estimativas aproximadas de alimentos, quantidades, '
                    'calorias e macronutrientes. Essas estimativas podem '
                    'conter imprecisões e não devem ser tratadas como '
                    'medições exatas. Você pode e deve revisar e ajustar os '
                    'valores sempre que julgar necessário.',
              ),
              const _TermsSection(
                title: '4. O JacalorIA não presta aconselhamento médico',
                body:
                    'O JacalorIA é uma ferramenta de organização e '
                    'acompanhamento pessoal. As informações exibidas no '
                    'aplicativo não constituem aconselhamento médico, '
                    'nutricional ou de saúde. Antes de iniciar qualquer '
                    'dieta, programa de emagrecimento ou mudança relevante '
                    'de hábitos alimentares, consulte um médico ou '
                    'nutricionista. Não utilize o aplicativo como substituto '
                    'de acompanhamento profissional, especialmente em caso '
                    'de condições de saúde preexistentes, gravidez ou '
                    'transtornos alimentares.',
              ),
              const _TermsSection(
                title: '5. Cadastro e conta',
                body:
                    'Para utilizar o JacalorIA é necessário criar uma conta '
                    'com nome, e-mail e senha, ou por meio do login com '
                    'Google. Você é responsável por manter a '
                    'confidencialidade de suas credenciais e por todas as '
                    'atividades realizadas em sua conta. As informações '
                    'fornecidas no cadastro e no onboarding (como data de '
                    'nascimento, peso, altura, sexo, objetivo e nível de '
                    'atividade) devem ser verdadeiras e atualizadas, pois '
                    'são utilizadas para calcular suas metas.',
              ),
              const _TermsSection(
                title: '6. Dados coletados e privacidade',
                body:
                    'Para o funcionamento do aplicativo, coletamos e '
                    'tratamos: dados de conta (nome, e-mail); dados de '
                    'perfil informados por você (data de nascimento, peso, '
                    'altura, sexo, objetivo, nível de atividade e metas); '
                    'conteúdo enviado por você (fotos e descrições de '
                    'refeições, avatar); dados sociais (amigos, grupos e '
                    'convites); dados de gamificação (missões, moedas '
                    'virtuais e sequências de uso); e dados de uso do '
                    'aplicativo para fins de melhoria do serviço. As fotos e '
                    'descrições de refeições são processadas por serviços '
                    'de inteligência artificial de terceiros exclusivamente '
                    'para gerar as estimativas nutricionais. O tratamento de '
                    'dados pessoais observa a Lei Geral de Proteção de '
                    'Dados (Lei nº 13.709/2018 — LGPD). Você pode solicitar '
                    'a exclusão de sua conta e de seus dados a qualquer '
                    'momento pelo canal de suporte do aplicativo.',
              ),
              const _TermsSection(
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
              const _TermsSection(
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
              const _TermsSection(
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
              const _TermsSection(
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
              const _TermsSection(
                title: '11. Encerramento de conta',
                body:
                    'Você pode parar de usar o aplicativo e solicitar a '
                    'exclusão de sua conta a qualquer momento. Podemos '
                    'suspender ou encerrar contas que violem estes Termos, '
                    'mediante análise do caso.',
              ),
              const _TermsSection(
                title: '12. Alterações destes Termos',
                body:
                    'Estes Termos podem ser atualizados periodicamente para '
                    'refletir mudanças no aplicativo ou na legislação. A '
                    'versão vigente estará sempre disponível no aplicativo, '
                    'com a data da última atualização. O uso continuado do '
                    'JacalorIA após alterações significa concordância com a '
                    'nova versão.',
              ),
              const _TermsSection(
                title: '13. Contato',
                body:
                    'Em caso de dúvidas sobre estes Termos, sobre o '
                    'tratamento de seus dados ou para solicitar a exclusão '
                    'de sua conta, utilize o canal "Suporte" disponível no '
                    'aplicativo.',
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
