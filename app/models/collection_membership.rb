class CollectionMembership < ApplicationRecord
  belongs_to :collection
  belongs_to :product
end
