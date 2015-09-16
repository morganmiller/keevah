require "logger"
require "faker"
require "capybara"
require "capybara/poltergeist"
require "active_support"
require "active_support/core_ext"

module LoadScript
  class Session
    include Capybara::DSL
    attr_reader :host
    def initialize(host = nil)
      Capybara.default_driver = :poltergeist
      @host = host || "http://localhost:3000"
    end

    def logger
      @logger ||= Logger.new("./log/requests.log")
    end

    def session
      @session ||= Capybara::Session.new(:poltergeist)
    end

    def run
      while true
        run_action(actions.sample)
      end
    end

    def run_action(name)
      benchmarked(name) do
        send(name)
      end
    rescue Capybara::Poltergeist::TimeoutError
      logger.error("Timed out executing Action: #{name}. Will continue.")
    end

    def benchmarked(name)
      logger.info "Running action #{name}"
      start = Time.now
      val = yield
      logger.info "Completed #{name} in #{Time.now - start} seconds"
      val
    end

    def actions
      [
        :browse_loan_requests,
        :sign_up_as_lender,
        :browse_loan_request_pages,
        :browse_categories,
        :browse_categories_pages,
        :borrower_sign_up,
        :new_borrower_creates_loan_request
      ]
    end

    def log_in(email="demo+horace@jumpstartlab.com", pw="password")
      log_out
      session.visit host
      session.click_link("Log In")
      session.fill_in("email_address", with: email)
      session.fill_in("password", with: pw)
      session.click_link_or_button("Login")
    end

    def browse_loan_requests
      session.visit "#{host}/browse"
      session.all(".lr-about").sample.click
      puts "browsing loan requests"
    end

    def browse_loan_request_pages
      session.visit "#{host}/browse"
      session.all(".flickr_pagination").sample.click
    end

    def browse_categories
      session.visit "#{host}/browse"
      session.all(".categories").sample.click
    end

    def browse_categories_pages
      session.visit "#{host}/browse"
      session.all(".categories").sample.click
      session.all(".flickr_pagination").sample.click
    end

    def borrower_sign_up(name = new_user_name)
      log_out
      session.find("#sign-up-as-borrower").click
      session.within("#borrowerSignUpModal") do
        session.fill_in("user_name", with: name)
        session.fill_in("user_email", with: new_user_email(name))
        session.fill_in("user_password", with: "password")
        session.fill_in("user_password_confirmation", with: "password")
        session.click_link_or_button "Create Account"
      end
      puts "signing up as borrower"
    end

    def new_borrower_creates_loan_request
      borrower_sign_up
      session.find(".btn-info").click
      session.within("#borrowerSignUpModal") do
        session.fill_in("title", with: new_title)
        session.fill_in("image_url", with: "http://exmoorpet.com/wp-content/uploads/2012/08/cat.png")
        session.fill_in("description", with: new_description)
        session.fill_in("requested_by_date", with: new_request_date)
        session.fill_in("repayment_begin_date", with: new_repayment_date)
        session.select("Education", from: "loan_request_category")
        session.click_link_or_button "Submit"
      end
    end

    def new_title
      Faker::Commerce.product_name
    end
    def new_description
      Faker::Company.catch_phrase
    end
    def new_request_date
      Faker::Time.between(7.days.ago, 3.days.ago)
    end
    def new_repayment_date
      Faker::Time.between(3.days.ago, Time.now)
    end

    def log_out
      session.visit host
      if session.has_content?("Log out")
        session.find("#logout").click
      end
    end

    def new_user_name
      "#{Faker::Name.name} #{Time.now.to_i}"
    end

    def new_user_email(name)
      "TuringPivotBots+#{name.split.join}@gmail.com"
    end

    def sign_up_as_lender(name = new_user_name)
      log_out
      session.find("#sign-up-as-lender").click
      session.within("#lenderSignUpModal") do
        session.fill_in("user_name", with: name)
        session.fill_in("user_email", with: new_user_email(name))
        session.fill_in("user_password", with: "password")
        session.fill_in("user_password_confirmation", with: "password")
        session.click_link_or_button "Create Account"
      end
      puts "signing up as lender"
    end

    def categories
      ["Agriculture", "Education", "Community"]
    end
  end
end
