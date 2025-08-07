defmodule EmailCollector.MailerTest do
  use ExUnit.Case
  import Swoosh.TestAssertions

  setup do
    :ok
  end

  test "send_email/4 sends an email" do
    to = "test@example.com"
    subject = "Test Email"
    html_body = "<h1>Hello from Email Collection</h1>"
    text_body = "Hello from Email Collection"

    assert {:ok, _} = EmailCollector.Mailer.send_email(to, subject, html_body, text_body)

    assert_email_sent(fn email ->
      assert Enum.map(email.to, fn {_name, addr} -> addr end) == [to]
      assert email.subject == subject
      assert email.html_body =~ "Hello"
      assert email.text_body =~ "Hello"
    end)
  end

  test "send_password_reset_email/2 sends a password reset email" do
    email = "test@example.com"
    reset_url = "http://localhost:4000/auth/reset-password?token=test-token"

    assert {:ok, _} = EmailCollector.Mailer.send_password_reset_email(email, reset_url)

    assert_email_sent(fn sent ->
      assert Enum.map(sent.to, fn {_name, addr} -> addr end) == [email]
      assert sent.subject =~ "Password Reset"
      assert sent.html_body =~ reset_url
      assert sent.text_body =~ reset_url
    end)
  end
end
