require 'test_helper'

class V01::PlanningsGetTest < ActiveSupport::TestCase

  include Rack::Test::Methods

  def app
    Rails.application
  end

  def api(path, params = {})
    Addressable::Template.new("/api/0.1/#{path}{?query*}").expand(query: params).to_s
  end

  setup do
    @planning = plannings :planning_one
    @user = @planning.customer.users.take
  end

  test 'Export Planning' do
    %w(json xml ics).each do |format|
      get api("/plannings/#{@planning.id}.#{format}", { api_key: @user.api_key })
      assert last_response.ok?, last_response.body
    end
  end

  test 'Export Plannings as iCalendar' do
    get api('/plannings.ics', { api_key: @user.api_key })
    assert last_response.ok?, last_response.body
  end

  test 'Export Planning as iCalendar with E-Mail' do
    get api("/plannings/#{@planning.id}.ics", { api_key: @user.api_key, email: 1 })
    assert_equal 204, last_response.status
  end

  test 'Get active plannings only' do
    get api('/plannings.json', { api_key: @user.api_key, active: true })
    assert last_response.ok?, last_response.body
    response = JSON.parse(last_response.body)
    assert_equal Planning.where(customer_id: @planning.customer.id).where(active: true).count, response.size
  end

  test 'Get plannings according to begin or end dates' do
    get api('/plannings.json', { api_key: @user.api_key, begin_date: '18-04-2017' })
    assert last_response.ok?, last_response.body
    response = JSON.parse(last_response.body)
    assert_equal Planning.where(customer_id: @planning.customer.id).where('begin_date >= ?', '18-04-2017').count, response.size

    get api('/plannings.json', { api_key: @user.api_key, end_date: '26-04-2017' })
    assert last_response.ok?, last_response.body
    response = JSON.parse(last_response.body)
    assert_equal Planning.where(customer_id: @planning.customer.id).where('end_date <= ?', '26-04-2017').count, response.size

    get api('/plannings.json', { api_key: @user.api_key, begin_date: '18-04-2017', end_date: '26-04-2017' })
    assert last_response.ok?, last_response.body
    response = JSON.parse(last_response.body)
    assert_equal Planning.where(customer_id: @planning.customer.id).where('begin_date >= ? AND end_date <= ?', '18-04-2017', '26-04-2017').count, response.size
  end

  test 'Get plannings with specific tags' do
    first_tag = @planning.customer.tags.first
    second_tag = @planning.customer.tags.second

    @planning.update(tags: [first_tag, second_tag])

    get api('/plannings.json', { api_key: @user.api_key, tags: "#{first_tag.label}" })
    assert last_response.ok?, last_response.body
    response = JSON.parse(last_response.body)
    assert_equal Planning.joins(:tags).where(tags: {label: first_tag.label}).reorder('tags.id').size, response.size

    get api('/plannings.json', { api_key: @user.api_key, tags: "#{first_tag.label},#{second_tag.label}" })
    assert last_response.ok?, last_response.body
    response = JSON.parse(last_response.body)

    assert_equal Planning.where(customer_id: @planning.customer.id).joins(:tags).where(tags: {label: [first_tag.label, second_tag.label]}).reorder('tags.id').distinct.size, response.size
  end
end
