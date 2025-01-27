class Mailer < ApplicationMailer
  after_action :prevent_delivery_to_users_without_email, except: [:newsletter]

  helper :text_with_links
  helper :mailer
  helper :users

  def comment(comment)
    @comment = comment
    @commentable = comment.commentable
    @email_to = @commentable.author.email
    set_footer_img
    with_user(@commentable.author) do
      subject = t('mailers.comment.subject', commentable: t("activerecord.models.#{@commentable.class.name.underscore}", count: 1).downcase)
      mail(to: @email_to, subject: subject) if @commentable.present? && @commentable.author.present?
    end
  end

  def reply(reply)
    @reply = reply
    @commentable = @reply.commentable
    parent = Comment.find(@reply.parent_id)
    @recipient = parent.author
    @email_to = @recipient.email
    set_footer_img
    with_user(@recipient) do
      mail(to: @email_to, subject: t('mailers.reply.subject')) if @commentable.present? && @recipient.present?
    end
  end

  def email_verification(user, recipient, token, document_type, document_number)
    @user = user
    @email_to = recipient
    @token = token
    @document_type = document_type
    @document_number = document_number

    with_user(user) do
      mail(to: @email_to, subject: t('mailers.email_verification.subject'))
    end
  end

  def unfeasible_spending_proposal(spending_proposal)
    @spending_proposal = spending_proposal
    @author = spending_proposal.author
    @email_to = @author.email

    with_user(@author) do
      mail(to: @email_to, subject: t('mailers.unfeasible_spending_proposal.subject', code: @spending_proposal.code))
    end
  end

  def direct_message_for_receiver(direct_message)
    @direct_message = direct_message
    @receiver = @direct_message.receiver
    @email_to = @receiver.email
    set_footer_img
    with_user(@receiver) do
      mail(to: @email_to, subject: t('mailers.direct_message_for_receiver.subject'))
    end
  end

  def direct_message_for_sender(direct_message)
    @direct_message = direct_message
    @sender = @direct_message.sender
    @email_to = @sender.email
    set_footer_img
    with_user(@sender) do
      mail(to: @email_to, subject: t('mailers.direct_message_for_sender.subject'))
    end
  end

  def proposal_notification_digest(user, notifications)
    @notifications = notifications
    @email_to = user.email

    with_user(user) do
      mail(to: @email_to, subject: t('mailers.proposal_notification_digest.title', org_name: Setting['org_name']))
    end
  end

  def user_invite(email)
    @email_to = email

    I18n.with_locale(I18n.default_locale) do
      mail(to: @email_to, subject: t('mailers.user_invite.subject', org_name: Setting["org_name"]))
    end
  end

  def budget_investment_created(investment)
    @investment = investment
    @email_to = @investment.author.email

    with_user(@investment.author) do
      mail(to: @email_to, subject: t('mailers.budget_investment_created.subject'))
    end
  end

  def budget_investment_unfeasible(investment)
    @investment = investment
    @author = investment.author
    @email_to = @author.email

    with_user(@author) do
      mail(to: @email_to, subject: t('mailers.budget_investment_unfeasible.subject', code: @investment.code))
    end
  end

  def budget_investment_selected(investment)
    @investment = investment
    @author = investment.author
    @email_to = @author.email

    with_user(@author) do
      mail(to: @email_to, subject: t('mailers.budget_investment_selected.subject', code: @investment.code))
    end
  end

  def budget_investment_unselected(investment)
    @investment = investment
    @author = investment.author
    @email_to = @author.email

    with_user(@author) do
      mail(to: @email_to, subject: t('mailers.budget_investment_unselected.subject', code: @investment.code))
    end
  end

  def newsletter(newsletter, recipient_email)
    @newsletter = newsletter
    set_footer_img
    mail(to: @newsletter.email_to, bcc: recipient_email, from: @newsletter.from, subject: @newsletter.subject)
  end

  def email_ticket_vote(poll, token, user)
    @poll = poll
    @token = token
    @email_to = user.email
    set_footer_img
    mail(to: @email_to, subject: 'Constancia de Votación')
  end

  def welcome_email(user)
    @email_to = user.email
    set_header_welcome_img
    set_footer_img
    mail(to: @email_to, subject: 'Bienvenido')
  end

  private

  def with_user(user, &block)
    I18n.with_locale(user.locale) do
      yield
    end
  end

  def prevent_delivery_to_users_without_email
    if @email_to.blank?
      mail.perform_deliveries = false
    end
  end

  def set_header_img
    attachments.inline['header_email.gif'] = File.read("#{Rails.root}/app/assets/images/custom/header_email.png")
  end

  def set_header_welcome_img
    attachments.inline['header_welcome_email.png'] = File.read("#{Rails.root}/app/assets/images/custom/header_welcome_email.png")
  end

  def set_footer_img
    attachments.inline['signature_email.gif'] = File.read("#{Rails.root}/app/assets/images/custom/signature_email.gif")
  end
end
