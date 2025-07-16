defmodule EmailCollector.MailerTest do
  use ExUnit.Case
  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "send_email/4 sends an email via AWS SES" do
    to = "test@example.com"
    subject = "Test Email"
    html_body = "<h1>Hello from FastCollect</h1>"
    text_body = "Hello from FastCollect"

    # Mock the ExAws.request call
    EmailCollector.ExAwsMock
    |> expect(:request, fn _operation -> {:ok, %{message_id: "test-message-id"}} end)

    result = EmailCollector.Mailer.send_email(to, subject, html_body, text_body)
    assert {:ok, %{message_id: "test-message-id"}} = result
  end

  test "send_password_reset_email/2 sends a password reset email" do
    email = "test@example.com"
    reset_url = "http://localhost:4000/auth/reset-password?token=test-token"

    # Mock the ExAws.request call
    EmailCollector.ExAwsMock
    |> expect(:request, fn _operation -> {:ok, %{message_id: "test-message-id"}} end)

    result = EmailCollector.Mailer.send_password_reset_email(email, reset_url)
    assert {:ok, %{message_id: "test-message-id"}} = result
  end

  test "send_password_reset_email/2 generates proper email content" do
    email = "test@example.com"
    reset_url = "http://localhost:4000/auth/reset-password?token=test-token"

    # Mock the ExAws.request call
    EmailCollector.ExAwsMock
    |> expect(:request, fn _operation -> {:ok, %{message_id: "test-message-id"}} end)

    result = EmailCollector.Mailer.send_password_reset_email(email, reset_url)
    assert {:ok, %{message_id: "test-message-id"}} = result
  end
end 