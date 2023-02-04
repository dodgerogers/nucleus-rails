require "test_helper"

class ExamplesControllerTest < ActionDispatch::IntegrationTest
  def setup
    host! "nucleus"
  end

  test "with json format" do
    get "/users.json"

    assert_response 200

    expected_payload = "{\"a\":{\"nested\":{\"hash\":\"value\"}},\"b\":[4,5,6]}"
    assert_equal(expected_payload, response.body)

    response_body = JSON.parse(expected_payload)
    assert(response_body.is_a?(Hash))
  end

  test "with xml format" do
    get "/users.xml"

    assert_response 200

    expected_payload = <<-XML.squish
      <?xml version="1.0" encoding="UTF-8"?>
      <hash>
        <name>Bob</name>
        <ids type="array">
          <id type="integer">1</id>
          <id type="integer">2</id>
          <id type="integer">3</id>
        </ids>
      </hash>
    XML
    assert_equal(expected_payload, response.body.squish)
  end

  test "with csv format" do
    get "/users.csv"

    assert_response 200

    expected_payload = "Bob\n1-2-3"
    assert_equal(expected_payload, response.body)
  end

  test "with pdf format" do
    get "/users.pdf"

    assert_response 200

    expected_payload = "%PDF-1. trailer<</Root<</Bob<</Bob[<</MediaBox[0 0 3 3]>>]>>>>>>"
    assert_equal(expected_payload, response.body)
  end

  test "with text format" do
    get "/users.text"

    assert_response 200

    expected_payload = "My name is Bob, my ID's are 1, 2, 3"
    assert_equal(expected_payload, response.body)
  end

  test "rendering nothing" do
    get "/user.json"

    assert_response 204
    assert_equal("", response.body)
    assert_equal("value", response.headers["My-Custom-Headers"])
  end
end
