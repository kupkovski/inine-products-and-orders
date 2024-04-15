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
  gem "pry"
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

  create_table :orders, force: true do |t|
    t.references :customer
    t.references :product
    t.integer :price_cents
  end

  create_table :orders_products, force: true do |t|
    t.references :order
    t.references :product
  end
end

class Customer < ActiveRecord::Base
  has_many :orders
end

class Product < ActiveRecord::Base
  has_and_belongs_to_many :orders

  validates :path, :name, presence: true
  validates :path, format: { with: /\A[a-zA-Z'-]*\z/, message: "must only contain letters, numbers, or dashes" }
end

class Order < ActiveRecord::Base
  belongs_to              :customer
  has_and_belongs_to_many :products

  scope :top_revenue_products, ->(number_of_products) do
    Product.joins(:orders).
      group('orders_products.product_id').
      order('sum(products.price_cents) DESC')
  end
end

class OrdersProduct < ActiveRecord::Base
  belongs_to :order
  belongs_to :product
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
  def teardown
    Customer.delete_all
    Product.delete_all
    Order.delete_all
  end

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

  def test_top_products_query
    customer = Customer.create!(name: 'Fake Customer')
    number_of_products = Product.count
    number_of_orders = Order.count

    products_data = [
      { name: 'MacOs',             path: 'path-to-macos',   price_cents: 199_99 },
      { name: 'Linux',             path: 'path-to-linux',   price_cents: 0 },
      { name: 'Windows',           path: 'path-to-windows', price_cents: 299_99 },
      { name: 'GloBright',         path: 'path-to-windows', price_cents: 99_99 },
      { name: 'LumniShare',        path: 'path-to-windows', price_cents: 95_99 },
      { name: 'Radiance X',        path: 'path-to-windows', price_cents: 12_00 },
      { name: 'Pro Series',        path: 'path-to-windows', price_cents: 127_80 },
      { name: 'Top Rated',         path: 'path-to-windows', price_cents: 11_99 },
      { name: 'Intuitive Systems', path: 'path-to-windows', price_cents: 87_88 },
      { name: 'Low Bugdet System', path: 'path-to-windows', price_cents: 0 },
    ]

    created_products = products_data.map do |product_data|
      Product.create!(product_data)
    end


    # creating the orders:
    # 2 for MacOs
    # 2 for Linux
    # 2 for Windows
    # 2 for GlobBright
    # 2 for Top Rated

    Order.create!(products: [created_products[0]], customer: customer, price_cents: created_products[0].price_cents)
    Order.create!(products: [created_products[0]], customer: customer, price_cents: created_products[0].price_cents)
    Order.create!(products: [created_products[1]], customer: customer, price_cents: created_products[1].price_cents)
    Order.create!(products: [created_products[1]], customer: customer, price_cents: created_products[1].price_cents)
    Order.create!(products: [created_products[2]], customer: customer, price_cents: created_products[2].price_cents)
    Order.create!(products: [created_products[2]], customer: customer, price_cents: created_products[2].price_cents)
    Order.create!(products: [created_products[3]], customer: customer, price_cents: created_products[3].price_cents)
    Order.create!(products: [created_products[3]], customer: customer, price_cents: created_products[3].price_cents)
    Order.create!(products: [created_products[7]], customer: customer, price_cents: created_products[7].price_cents)
    Order.create!(products: [created_products[7]], customer: customer, price_cents: created_products[7].price_cents)


    assert_equal number_of_products + 10, Product.count
    assert_equal number_of_orders + 10, Order.count

    expected = [
      created_products[2], # Windows
      created_products[0], # MacOs
      created_products[3], # GloBright
      created_products[7], # Top Rated
      created_products[1], # Linux
    ]

    assert_equal expected, Order.top_revenue_products(5).to_a
  end
end
