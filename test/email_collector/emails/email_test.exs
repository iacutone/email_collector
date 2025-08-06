defmodule EmailCollector.Emails.EmailTest do
  use EmailCollector.DataCase

  alias EmailCollector.Emails.Email

  describe "email validation" do
    test "validates correct email addresses" do
      valid_emails = [
        "test@example.com",
        "user.name@domain.co.uk",
        "user+tag@example.org",
        "123@numbers.com",
        "user@subdomain.example.com",
        "user@example-domain.com"
      ]

      for email <- valid_emails do
        changeset = Email.changeset(%Email{}, %{
          name: email,
          user_id: 1,
          campaign_id: 1
        })

        assert changeset.valid?
        assert changeset.errors == []
      end
    end

    test "rejects invalid email addresses" do
      changeset = Email.changeset(%Email{}, %{
        name: "not-an-email",
        user_id: 1,
        campaign_id: 1
      })

      refute changeset.valid?
      assert "must be a valid email address" in errors_on(changeset).name
    end

    test "rejects email addresses with invalid characters" do
      changeset = Email.changeset(%Email{}, %{
        name: "user<@example.com",
        user_id: 1,
        campaign_id: 1
      })

      refute changeset.valid?
      assert "must be a valid email address" in errors_on(changeset).name
    end

    test "accepts email addresses with special characters in local part" do
      valid_emails = [
        "user+tag@example.com",
        "user-tag@example.com",
        "user.tag@example.com",
        "user_tag@example.com",
        "user%tag@example.com",
        "user!tag@example.com",
        "user#tag@example.com",
        "user$tag@example.com",
        "user&tag@example.com",
        "user*tag@example.com",
        "user=tag@example.com",
        "user?tag@example.com",
        "user^tag@example.com",
        "user`tag@example.com",
        "user{tag}@example.com",
        "user~tag@example.com"
      ]

      for email <- valid_emails do
        changeset = Email.changeset(%Email{}, %{
          name: email,
          user_id: 1,
          campaign_id: 1
        })

        assert changeset.valid?
        assert changeset.errors == []
      end
    end

    test "accepts internationalized email addresses" do
      valid_emails = [
        "user@xn--example-6ja.com",  # IDN domain
        "user@example.co.jp",
        "user@example.de",
        "user@example.fr"
      ]

      for email <- valid_emails do
        changeset = Email.changeset(%Email{}, %{
          name: email,
          user_id: 1,
          campaign_id: 1
        })

        assert changeset.valid?
        assert changeset.errors == []
      end
    end
  end

  describe "required fields" do
    test "requires name field" do
      changeset = Email.changeset(%Email{}, %{
        user_id: 1,
        campaign_id: 1
      })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "requires user_id field" do
      changeset = Email.changeset(%Email{}, %{
        name: "test@example.com",
        campaign_id: 1
      })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).user_id
    end

    test "requires campaign_id field" do
      changeset = Email.changeset(%Email{}, %{
        name: "test@example.com",
        user_id: 1
      })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).campaign_id
    end
  end
end
