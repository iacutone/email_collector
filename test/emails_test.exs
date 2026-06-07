defmodule EmailCollector.EmailsTest do
  use EmailCollector.DataCase, async: true

  alias EmailCollector.Emails
  alias EmailCollector.Accounts
  alias EmailCollector.Campaigns

  describe "emails" do
    setup do
      {:ok, user} =
        Accounts.create_user(%{
          email: "e@example.com",
          password: "pw1234",
          password_confirmation: "pw1234"
        })

      {:ok, campaign} = Campaigns.create_campaign(%{name: "C1", user_id: user.id})
      %{user: user, campaign: campaign}
    end

    test "creates an email and associates with user and campaign", %{
      user: user,
      campaign: campaign
    } do
      attrs = %{name: "recipient@example.com", user_id: user.id, campaign_id: campaign.id}
      {:ok, email} = Emails.create_email(attrs)
      assert email.name == "recipient@example.com"
      assert email.user_id == user.id
      assert email.campaign_id == campaign.id
      assert email.subscribed == true  # Default value
    end

    test "creates email with misc data", %{user: user, campaign: campaign} do
      misc_data = %{"first_name" => "John", "last_name" => "Doe", "comments" => "Interested in updates"}
      
      attrs = %{
        name: "john@example.com", 
        user_id: user.id, 
        campaign_id: campaign.id,
        misc: misc_data
      }
      
      {:ok, email} = Emails.create_email(attrs)
      assert email.misc == misc_data
    end

    test "validates email format", %{user: user, campaign: campaign} do
      invalid_emails = ["invalid", "@example.com", "test@", "test.com", ""]
      
      for invalid_email <- invalid_emails do
        attrs = %{name: invalid_email, user_id: user.id, campaign_id: campaign.id}
        {:error, changeset} = Emails.create_email(attrs)
        assert "must be a valid email address" in errors_on(changeset).name
      end
    end

    test "requires name, user_id, and campaign_id", %{user: user, campaign: campaign} do
      # Missing name
      {:error, changeset} = Emails.create_email(%{user_id: user.id, campaign_id: campaign.id})
      assert "can't be blank" in errors_on(changeset).name

      # Missing user_id
      {:error, changeset} = Emails.create_email(%{name: "test@example.com", campaign_id: campaign.id})
      assert "can't be blank" in errors_on(changeset).user_id

      # Missing campaign_id
      {:error, changeset} = Emails.create_email(%{name: "test@example.com", user_id: user.id})
      assert "can't be blank" in errors_on(changeset).campaign_id
    end

    test "enforces unique email per campaign", %{user: user, campaign: campaign} do
      attrs = %{name: "duplicate@example.com", user_id: user.id, campaign_id: campaign.id}
      
      # First creation should succeed
      {:ok, _email} = Emails.create_email(attrs)
      
      # Second creation should fail
      {:error, changeset} = Emails.create_email(attrs)
      assert "An email with this name already exists in this campaign" in errors_on(changeset).name
    end

    test "allows same email in different campaigns", %{user: user} do
      {:ok, campaign1} = Campaigns.create_campaign(%{name: "Campaign 1", user_id: user.id})
      {:ok, campaign2} = Campaigns.create_campaign(%{name: "Campaign 2", user_id: user.id})
      
      email_name = "same@example.com"
      
      # Create in first campaign
      {:ok, email1} = Emails.create_email(%{
        name: email_name, 
        user_id: user.id, 
        campaign_id: campaign1.id
      })
      
      # Create same email in second campaign should succeed
      {:ok, email2} = Emails.create_email(%{
        name: email_name, 
        user_id: user.id, 
        campaign_id: campaign2.id
      })
      
      assert email1.name == email2.name
      assert email1.campaign_id != email2.campaign_id
    end

    test "retrieves emails by campaign", %{user: user, campaign: campaign} do
      {:ok, email1} =
        Emails.create_email(%{
          name: "user1@example.com",
          user_id: user.id,
          campaign_id: campaign.id
        })

      {:ok, email2} =
        Emails.create_email(%{
          name: "user2@example.com",
          user_id: user.id,
          campaign_id: campaign.id
        })

      emails = Emails.list_emails_by_campaign(campaign.id)
      assert Enum.any?(emails, &(&1.id == email1.id))
      assert Enum.any?(emails, &(&1.id == email2.id))
    end

    test "list_emails_by_campaign returns empty list for non-existent campaign" do
      emails = Emails.list_emails_by_campaign("non-existent-id")
      assert emails == []
    end

    test "get_email_by_campaign_and_name finds email", %{user: user, campaign: campaign} do
      {:ok, email} = Emails.create_email(%{
        name: "findme@example.com",
        user_id: user.id,
        campaign_id: campaign.id
      })

      found_email = Emails.get_email_by_campaign_and_name(campaign.id, "findme@example.com")
      assert found_email.id == email.id
      assert found_email.name == email.name
    end

    test "get_email_by_campaign_and_name returns nil for non-existent email", %{campaign: campaign} do
      result = Emails.get_email_by_campaign_and_name(campaign.id, "nonexistent@example.com")
      assert result == nil
    end

    test "get_email_by_campaign_and_name returns nil for wrong campaign", %{user: user} do
      {:ok, campaign1} = Campaigns.create_campaign(%{name: "Campaign 1", user_id: user.id})
      {:ok, campaign2} = Campaigns.create_campaign(%{name: "Campaign 2", user_id: user.id})
      
      {:ok, _email} = Emails.create_email(%{
        name: "test@example.com",
        user_id: user.id,
        campaign_id: campaign1.id
      })

      # Try to find in different campaign
      result = Emails.get_email_by_campaign_and_name(campaign2.id, "test@example.com")
      assert result == nil
    end

    test "unsubscribe_email sets subscribed to false", %{user: user, campaign: campaign} do
      {:ok, email} = Emails.create_email(%{
        name: "unsubscribe@example.com",
        user_id: user.id,
        campaign_id: campaign.id
      })

      assert email.subscribed == true

      {:ok, updated_email} = Emails.unsubscribe_email(email)
      assert updated_email.subscribed == false
      assert updated_email.id == email.id
    end

    test "unsubscribe_email is idempotent", %{user: user, campaign: campaign} do
      {:ok, email} = Emails.create_email(%{
        name: "already_unsubscribed@example.com",
        user_id: user.id,
        campaign_id: campaign.id
      })

      # Unsubscribe once
      {:ok, updated_email1} = Emails.unsubscribe_email(email)
      assert updated_email1.subscribed == false

      # Unsubscribe again
      {:ok, updated_email2} = Emails.unsubscribe_email(updated_email1)
      assert updated_email2.subscribed == false
      assert updated_email2.id == updated_email1.id
    end

    test "get_email! raises when email not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Emails.get_email!(999_999)
      end
    end

    test "get_email! returns email when found", %{user: user, campaign: campaign} do
      {:ok, email} = Emails.create_email(%{
        name: "findbyid@example.com",
        user_id: user.id,
        campaign_id: campaign.id
      })

      found_email = Emails.get_email!(email.id)
      assert found_email.id == email.id
      assert found_email.name == email.name
    end
  end
end
