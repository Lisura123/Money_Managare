<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Welcome to Money Manager</title>
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
            <p style="margin:0 0 16px 0;">Your Money Manager account has been created by the administrator. You can now log in to the app using the credentials below:</p>

            {{-- Credentials box --}}
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:20px 0;">
              <tr>
                <td style="background-color:#F0F0F0;border:1px solid #DDDDDD;border-radius:8px;padding:20px 24px;">
                  <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                      <td style="padding:4px 0;">
                        <span style="font-size:13px;color:#666666;">Email:</span><br>
                        <strong style="font-size:15px;color:#1B2A4A;">{{ $userEmail }}</strong>
                      </td>
                    </tr>
                    <tr>
                      <td style="padding:10px 0 4px 0;border-top:1px solid #E0E0E0;margin-top:8px;">
                        <span style="font-size:13px;color:#666666;">Password:</span><br>
                        <strong style="font-size:15px;color:#1B2A4A;font-family:'Courier New',Courier,monospace;letter-spacing:2px;">{{ $plainPassword }}</strong>
                      </td>
                    </tr>
                    @if($showroomName)
                    <tr>
                      <td style="padding:10px 0 4px 0;border-top:1px solid #E0E0E0;">
                        <span style="font-size:13px;color:#666666;">Showroom:</span><br>
                        <strong style="font-size:15px;color:#1B2A4A;">{{ $showroomName }}</strong>
                      </td>
                    </tr>
                    @endif
                  </table>
                </td>
              </tr>
            </table>

            <p style="margin:0 0 24px 0;color:#E65100;font-size:13px;"><strong>For security, please change your password after your first login.</strong></p>

            {{-- CTA Button --}}
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:24px;">
              <tr>
                <td align="center">
                  <a href="{{ $appUrl }}" style="display:inline-block;background-color:#1B2A4A;color:#ffffff;text-decoration:none;font-size:14px;font-weight:bold;padding:12px 32px;border-radius:8px;">Open Money Manager</a>
                </td>
              </tr>
            </table>

            <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
              <tr>
                <td style="background-color:#FFF8E1;border-left:4px solid #FFC107;padding:12px 16px;border-radius:4px;">
                  <p style="margin:0;font-size:13px;color:#555555;"><strong>Keep your credentials confidential.</strong> Do not share your password with anyone.</p>
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
