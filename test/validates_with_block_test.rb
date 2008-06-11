require 'test/unit'
require 'rubygems'
gem 'activerecord'
require 'active_record'
require File.dirname(__FILE__) + '/../lib/validates_with_block'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + '/debug.log')
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'memory'])

silence_stream(STDOUT) do
  ActiveRecord::Schema.define do
    create_table 'users', :force => true do |user|
      user.string 'login', 'password'
      user.date 'birthday'
    end
  end
end

class User < ActiveRecord::Base
  validates_birthday do |birthday|
    birthday.present
  end

  validates_login do |login|
    login.formatted :with => /^[a-zA-Z]+$/ 
    login.length :within => 4..15
    login.unique
  end

  validates_password do |password|
    password.confirmed
  end
  
  attr_accessor :password_confirmation
end

class ValidatesWithBlockTest < Test::Unit::TestCase
  def setup
    User.destroy_all
  end

  def assert_user_errors_on( field )
    @user.valid?
    assert_not_nil @user.errors.on( field ), @user.errors.inspect
  end

  def new_user( atts = {} )
    @user = User.new atts
  end

  def test_confirmed
    new_user :password => 'password', :password_confirmation => 'passworf'
    assert_user_errors_on :password
  end
  
  def test_formatted
    new_user :login => '12345'
    assert_user_errors_on :login
  end
  
  def test_length
    new_user :login => 'thisloginistoodamnedlong'
    assert_user_errors_on :login
  end
  
  def test_present
    new_user
    assert_user_errors_on :birthday
  end
  
  def test_unique
    User.create(
      :birthday => Date.today, :login => 'billuser', :password => 'p',
      :password_confirmation => 'p'
    )
    new_user :login => 'billuser'
    assert_user_errors_on :login
  end
end
