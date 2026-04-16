<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Password Reset Code</title>
</head>
<body style="margin:0;padding:0;background-color:#F5F7FA;font-family:Arial,Helvetica,sans-serif;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#F5F7FA;padding:32px 0;">
  <tr>
    <td align="center">
      <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background-color:#ffffff;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.07);">

        {{-- Header --}}
        <tr>
          <td style="background-color:#1B2A4A;padding:20px 32px;text-align:center;">
            <span style="color:#ffffff;font-size:22px;font-weight:bold;letter-spacing:1px;">Money Manager</span>
          </td>
        </tr>

        {{-- Body --}}
        <tr>
          <td style="padding:32px 32px 24px 32px;color:#333333;font-size:14px;line-height:1.6;">
            <p style="margin:0 0 16px 0;">Hello <strong>{{ $userName }}</strong>,</p>
            <p style="margin:0 0 16px 0;">You requested a password reset for your Money Manager account. Use the code below to reset your password:</p>

            {{-- Code box --}}
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
              <tr>
                <td align="center" style="padding:24px 0;">
                  <table role="presentation" cellpadding="0" cellspacing="0">
                    <tr>
                      <td style="background-color:#F0F0F0;border:1px solid #DDDDDD;border-radius:8px;padding:20px 32px;text-align:center;">
                        <span style="font-size:36px;font-weight:bold;letter-spacing:12px;color:#1B2A4A;font-family:'Courier New',Courier,monospace;">{{ $code }}</span>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>
            </table>

            <p style="margin:0 0 16px 0;text-align:center;color:#666666;font-size:13px;">This code will expire in <strong>15 minutes</strong>.</p>

            <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
              <tr>
                <td style="background-color:#FFF8E1;border-left:4px solid #FFC107;padding:12px 16px;border-radius:4px;margin-top:16px;">
                  <p style="margin:0;font-size:13px;color:#555555;">If you did not request this password reset, please ignore this email. Your account is safe.</p>
                </td>
              </tr>
            </table>
          </td>
        </tr>

        {{-- Footer --}}
        <tr>
          <td style="background-color:#F5F7FA;padding:16px 32px;text-align:center;border-top:1px solid #E8ECF0;">
            <p style="margin:0;font-size:12px;color:#999999;">© 2026 Money Manager. This is an automated email, please do not reply.</p>
          </td>
        </tr>

      </table>
    </td>
  </tr>
</table>
</body>
</html>
