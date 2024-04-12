# This is a trivial single-file Rails application.
# You can run by typing ruby app.rb (it automatically runs bundler and uses an in-memory SQLite database).
#
# Your project is to fix this little app, implement a small piece of functionality,
# and then discuss some improvements on a larger scale.
# 1. Fix the syntax error.
# 2. Implement the functionality for the failing tests in the ProductTest class.
# 3. Implement the functionality (and tests) to find to top 5 products generating the most revenue.
# 4. Discuss how you would prevent a customer purchasing the same product twice in a live production version of this app.

require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"

  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "activerecord", "5.2.4.1"
  gem "sqlite3", "~> 1.3.6"
end

require "active_record"
require "minitest/autorun"
require "logger"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :customers, force: true do |t|
    t.string :name
    t.string :email
  end

  create_table :products, force: true do |t|
    t.string :name
    t.string :path
    t.integer :price_cents
  end

  create_table :orders force: true do |t|
    t.references :customer
    t.references :product
    t.integer :price_cents
  end
end

class Customer < ActiveRecord::Base
  has_many :orders
end

class Product < ActiveRecord::Base
  has_many :orders
end

class Order < ActiveRecord::Base
  belongs_to :customer
end

class OrderTest < Minitest::Test
  def test_order_creation
    customer = Customer.create! name: 'Basil', email: 'basil@hey.com'
    product = Product.create! name: 'My book', path: 'my-book'
    customer.orders << Order.create!

    assert_equal 1, customer.orders.count
    assert_equal 1, Order.count
    assert_equal customer.id, Order.first.customer.id
  end
end

# Implement these failing tests
class ProductTest < Minitest::Test
  def test_product_values_are_present
    product = Product.new
    assert product.invalid?
    assert_includes product.errors[:path], "can't be blank"
    assert_includes product.errors[:name], "can't be blank"
  end

  def test_product_path_is_valid
    product = Product.new name: 'My awesome book', path: 'my awesome book'
    assert product.invalid?
    assert_includes product.errors[:path], "must only contain letters, numbers, or dashes"
    product = Product.new name: 'My awesome book', path: 'my-awesome-book'
    assert product.valid?
  end
end
