require "test_helper"

class LocationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @location = locations(:one)
    sign_in_as(@user)
  end

  test "should get index" do
    get locations_url
    assert_response :success
  end

  test "should get new" do
    get new_location_url
    assert_response :success
  end

  test "should create location" do
    assert_difference("Location.count") do
      post locations_url, params: { location: { account_id: @location.account_id, name: @location.name } }
    end

    assert_redirected_to location_url(Location.last)
  end

  test "should show location" do
    get location_url(@location)
    assert_response :success
  end

  test "should get edit" do
    get edit_location_url(@location)
    assert_response :success
  end

  test "should update location" do
    patch location_url(@location), params: { location: { account_id: @location.account_id, name: @location.name } }
    assert_redirected_to location_url(@location)
  end

  test "should update location and collection_point" do
    @location = locations(:two)
    assert_not @location.collection_point?
    patch location_url(@location), params: { location: { name: "Updated Name", collection_point: "1" } }
    assert_redirected_to location_url(@location)
    @location.reload
    assert @location.collection_point?, "Collection point should have been updated to true"
  end

  test "should destroy location" do
    assert_difference("Location.count", -1) do
      delete location_url(@location)
    end

    assert_redirected_to locations_url
  end
end
