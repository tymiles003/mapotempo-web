module Confirmable
  extend ActiveSupport::Concern

  included do
    before_create :generate_confirmation_token
    after_create :send_welcome_email, unless: :admin?
  end

  def confirm!
    self.update! confirmed_at: Time.now
  end

  def confirmed?
    !self.confirmed_at.nil?
  end

  def generate_confirmation_token
    self.confirmation_token = Digest::SHA1.hexdigest [Time.now, rand].join
  end

  def send_welcome_email
    Mapotempo::Application.config.delayed_job_use ? UserMailer.delay.welcome_message(self) : UserMailer.welcome_message(self).deliver_now
    self.update! confirmation_sent_at: Time.now
  end
end
