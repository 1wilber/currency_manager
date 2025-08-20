class Customer < ApplicationRecord
  has_person_name
  validates :first_name, presence: true

  def label
    name
  end
end
