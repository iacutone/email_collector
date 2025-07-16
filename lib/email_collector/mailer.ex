defmodule EmailCollector.Mailer do
  @moduledoc """
  Custom mailer using AWS SES for sending emails.
  """

  @from "noreply@fastcollect.com"

  def send_email(to, subject, html_body, text_body) do
    message = %{
      subject: subject,
      body: %{html: html_body, text: text_body}
    }

    ExAws.SES.send_email(
      %{to: [to]},
      message,
      @from
    )
    |> ExAws.request()
  end

  def send_password_reset_email(email, reset_url) do
    subject = "Password Reset Request - FastCollect"

    html_body = """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Password Reset</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
      <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
        <h1 style="color: #2563eb;">FastCollect</h1>
        <h2>Password Reset Request</h2>
        <p>You requested a password reset for your FastCollect account.</p>
        <p>Click the button below to reset your password:</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="#{reset_url}" 
             style="background-color: #2563eb; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;">
            Reset Password
          </a>
        </div>
        <p>If you didn't request this password reset, you can safely ignore this email.</p>
        <p>This link will expire in 1 hour.</p>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #e5e7eb;">
        <p style="font-size: 12px; color: #6b7280;">
          If the button doesn't work, copy and paste this link into your browser:<br>
          <a href="#{reset_url}" style="color: #2563eb;">#{reset_url}</a>
        </p>
      </div>
    </body>
    </html>
    """

    text_body = """
    Password Reset Request - FastCollect

    You requested a password reset for your FastCollect account.

    Click the link below to reset your password:
    #{reset_url}

    If you didn't request this password reset, you can safely ignore this email.
    This link will expire in 1 hour.
    """

    send_email(email, subject, html_body, text_body)
  end
end 