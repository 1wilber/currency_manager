class Customer < ApplicationRecord
  has_person_name
  validates :first_name, presence: true
  has_many :transactions

  def label
    name
  end
end
