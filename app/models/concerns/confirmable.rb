module Confirmable
  extend ActiveSupport::Concern

  included do
    before_create :generate_confirmation_token
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
end
