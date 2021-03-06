class User < ActiveRecord::Base
	has_many :relationships,         foreign_key: "fan_id",
	                                   dependent: :destroy
	has_many :reverse_relationships, foreign_key: "followed_id",
	                                  class_name: "Relationship", 
	                                   dependent: :destroy
	has_many :followed_users,            through: :relationships,
	                                      source: :followed
  has_many :fans,                      through: :reverse_relationships
	has_many :microposts,dependent: :destroy
	validates :name, presence: true, length: {maximum: 50}
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+[a-z\d.]*\.[a-z]+\z/i
	validates :email, format: { with: VALID_EMAIL_REGEX },
	                  presence: true,
	                  uniqueness: { case_sensitive: false }
	validates :password, :password_confirmation, length: { minimum: 6 }
	before_save { self.email = email.downcase }
	before_create :create_remember_token

	has_secure_password
	def User.new_remember_token
		SecureRandom.urlsafe_base64
	end

	def User.encrypt(token)
		Digest::SHA1.hexdigest(token.to_s)
	end

	def feed
		Micropost.from_users_followed_by(self)
	end

	def follow!(other_user)
		self.relationships.create!(followed_id: other_user.id)
	end

	def follow_all!(users)
		users.each do |user|
			follow! user unless following? user
		end
	end

	def unfollow_all!(users)
		users.each do |user|
			unfollow! user if following? user
		end
	end

	def unfollow!(other_user)
		self.relationships.find_by(followed_id: other_user.id).destroy!
		
	end

	def following?(other_user)
		self.relationships.find_by(followed_id: other_user.id)
	end

	private
		def create_remember_token
			self.remember_token = User.encrypt(User.new_remember_token)
		end
end
