type VerificationEmailTemplateParams = {
  code: string;
  logoCid: string;
};

export function buildVerificationEmailHtml({
  code,
  logoCid,
}: VerificationEmailTemplateParams): string {
  return `
<!DOCTYPE html>
<html lang="pt-BR">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Código de verificação - Jacaloria</title>
  </head>
  <body style="margin: 0; padding: 0; background-color: #e7e7e7;">
    <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="background-color: #e7e7e7;">
      <tr>
        <td align="center" style="padding: 24px 12px;">
          <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="672" style="width: 672px; max-width: 672px; background-color: #f0f0f0; font-family: Arial, Helvetica, sans-serif; color: #193629;">
            <tr>
              <td style="padding: 89px 47px 0 47px;">
                <img src="cid:${logoCid}" alt="Jacaloria" width="338" height="91" style="display: block; width: 338px; max-width: 100%; height: auto; border: 0;" />
              </td>
            </tr>
            <tr>
              <td style="padding: 55px 47px 0 47px; font-size: 36px; line-height: 44px; font-weight: 700; color: #000000;">
                Olá! Seu código de verificação é:
              </td>
            </tr>
            <tr>
              <td style="padding: 55px 47px 0 47px; font-size: 64px; line-height: 1; font-weight: 700; color: #7cbf4d; letter-spacing: 2px;">
                ${code}
              </td>
            </tr>
            <tr>
              <td style="padding: 55px 47px 0 47px; width: 407px; max-width: 407px; font-size: 22px; line-height: 1.35; font-weight: 600; color: #193629;">
                Digite-o código no aplicativo para confirmar seu e-mail.
              </td>
            </tr>
            <tr>
              <td style="padding: 55px 47px 89px 47px; width: 439px; max-width: 439px; font-size: 20px; line-height: 1.2; font-weight: 400; color: #4d6559;">
                Este é um email enviado automaticamente e não recebemos respostas.
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>
`;
}
