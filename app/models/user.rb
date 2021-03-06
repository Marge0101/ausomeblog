class User < ActiveRecord::Base
  attr_accessor :remember_token,:activation_token,:reset_token
  before_save :downcase_email
  before_create :create_activation_digest
  has_many :microposts,dependent: :destroy
  # 私→他へ（フォロワー）
  has_many :active_relationships,class_name: "Relationship",
                                  foreign_key: "follower_id",
                                  dependent: :destroy
  has_many:following, through: :active_relationships,source: :followed
  
  
  # フォロワー→私
  has_many :passive_relationships,class_name: "Relationship",
                                  foreign_key: "followed_id",
                                  dependent: :destroy
  
  has_many:followers, through: :passive_relationships,source: :follower





    before_save{self.email=email.downcase}
    validates :name, presence: true,length:{maximum:50}
    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
    validates :email, presence: true, length: { maximum: 50 },
                  format: { with: VALID_EMAIL_REGEX },
                  uniqueness: true
    has_secure_password
    validates :password, presence: true,length:{maximum:6},allow_nil:true
    
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                 BCrypt::Engine.cost
    BCrypt::Password.create(string,cost:cost)  
  end
  # Reterns a random token.
  def User.new_token
    SecureRandom.urlsafe_base64
  end
  # Remembers a user in the database for use in persistent sessions.
  def remember
    self.remember_token=User.new_token
    update_attribute(:remember_digest,User.digest(remember_token))
  end
  # Returens true if the given token matches the diggest.<no5>
  
  #Try1
  # def authenicated?(remember_token)
  #   return false if remember_digest.nil?
  #   BCrypt::Password.new(remember_digest).is_password?(remember_token)
  # end
  
  def authenticated?(attribute,token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end
  
  
  #Forgets a user. ログアウトしたらcookieも削除時に使う
  def forget 
    update_attribute(:remember_digest,nil)
  end
  
  #Micropost Feed
  def feed
    # Micropost.where("user_id=:user_id", user_id: id)
    following_ids="SELECT followed_id FROM relationships WHERE follower_id = :user_id"
    Micropost.where("user_id IN(#{following_ids}) 
                  OR user_id = :user_id",user_id: id)
  end
  
  # Follows a user.
  def follow(other_user )
    # following << other_user
    active_relationships.create(followed_id: other_user.id)
  end

  # Unfollows a user.
  def unfollow(other_user )
    # following.delete(other_user)
    active_relationships.find_by(followed_id: other_user.id).destroy
  end

  # Returns true if the current user is following the other user.
  # followerかどうかを確認する為に入れる
  def following?(other_user)
    following. include?(other_user)
  end
  
  #Account activation
  #Activates an account
  # def activated
  #   update_attribute(:activated, true)
  #   update_attribute(:activaed_at, Time.zone.now)
  # end

  #Sends activativation mail.
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end
  
  #PW reset
  #Sets the PW reset attributes.
  def create_reset_digest
    self.reset_token =User.new_token
    update_attribute(:reset_digest, User.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def password_reset_expired?
    reset_sent_at<2.hours.ago
  end
  
  private

  #Convert email to all over-case.
  def downcase_email
    self.email = email.downcase
  end

#Creates and assigns the activation token and digest.  
  def create_activation_digest
    self.activation_token = User.new_token
    self.activation_digest = User.digest(activation_token)
  end


end
