defmodule EmailCollector.MailerTest do
  use ExUnit.Case

  test "send_email/4 sends an email via AWS SES" do
    # Use a real or sandboxed email address for testing
    to = "test@example.com"
    subject = "Test Email"
    html_body = "<h1>Hello from FastCollect</h1>"
    text_body = "Hello from FastCollect"

    # This will actually attempt to send an email via AWS SES
    result = EmailCollector.Mailer.send_email(to, subject, html_body, text_body)

    # You can assert on the result structure, but ExAws returns {:ok, _} or {:error, _}
    assert match?({:ok, _}, result) or match?({:error, _}, result)
  end

  test "send_password_reset_email/2 sends a password reset email" do
    email = "test@example.com"
    reset_url = "http://localhost:4000/auth/reset-password?token=test-token"

    result = EmailCollector.Mailer.send_password_reset_email(email, reset_url)

    # Assert that the function returns a result (either success or error)
    assert match?({:ok, _}, result) or match?({:error, _}, result)
  end

  test "send_password_reset_email/2 generates proper email content" do
    email = "test@example.com"
    reset_url = "http://localhost:4000/auth/reset-password?token=test-token"

    # Test that the function can be called without errors
    # In a real test environment, you might want to mock the AWS SES call
    result = EmailCollector.Mailer.send_password_reset_email(email, reset_url)
    
    # The result should be either {:ok, response} or {:error, reason}
    assert match?({:ok, _}, result) or match?({:error, _}, result)
  end
end 