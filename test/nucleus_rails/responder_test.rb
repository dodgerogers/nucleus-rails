require "test_helper"

class ExamplesControllerTest < ActionDispatch::IntegrationTest
  def setup
    host! "nucleus"
  end

  test "with json format" do
    get "/block_syntax.json"

    assert_response 200

    expected_payload = "{\"a\":{\"nested\":{\"hash\":\"value\"}},\"b\":[4,5,6]}"
    assert_equal(expected_payload, response.body)
    assert_equal("application/json; charset=utf-8", response.content_type)
  end

  test "with xml format" do
    get "/block_syntax.xml"

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
    assert_equal("application/xml; charset=utf-8", response.content_type)
  end

  test "with csv format" do
    get "/block_syntax.csv"

    assert_response 200

    expected_payload = "Bob\n1-2-3"
    assert_equal(expected_payload, response.body)
    assert_equal("text/csv", response.content_type)
    assert_equal(
      "attachment; filename=\"testview.csv\"; filename*=UTF-8''testview.csv",
      response.headers["Content-Disposition"]
    )
  end

  test "with pdf format" do
    get "/block_syntax.pdf"

    assert_response 200

    expected_payload = "%PDF-1. trailer<</Root<</Bob<</Bob[<</MediaBox[0 0 3 3]>>]>>>>>>"
    assert_equal(expected_payload, response.body)
    assert_equal("application/pdf", response.content_type)
    assert_equal(
      "attachment; filename=\"testview.pdf\"; filename*=UTF-8''testview.pdf",
      response.headers["Content-Disposition"]
    )
  end

  test "with text format" do
    get "/block_syntax.text"

    assert_response 200

    expected_payload = "My name is Bob, my ID's are 1, 2, 3"
    assert_equal(expected_payload, response.body)
    assert_equal("text/plain; charset=utf-8", response.content_type)
  end

  test "with html format" do
    get "/block_syntax.html"

    assert_response 200

    expected_payload = "<h1>Bob</h1><p>1, 2, 3</p>"
    assert_equal(expected_payload, response.body)
    assert_equal("text/html; charset=utf-8", response.content_type)
  end

  test "with svg format" do
    get "/block_syntax.svg"

    assert_response 200

    expected_payload = <<-SVG.squish
      <svg viewBox=".5 .5 3 4" fill="none" stroke="#20b2a" stroke-linecap="round">
        <path d="M1 4h-.001 V1h2v.001 M1 2.6 h1v.001"/>
      </svg>
    SVG
    assert_equal(expected_payload, response.body)
    assert_equal("image/svg+xml", response.content_type)
    assert_equal(
      "attachment; filename=\"testview.svg\"; filename*=UTF-8''testview.svg",
      response.headers["Content-Disposition"]
    )
  end

  test "rendering nothing" do
    get "/response_object.json"

    assert_response 204

    assert_equal("", response.body)
    assert_equal("value", response.headers["My-Custom-Headers"])
    assert_nil(response.content_type)
  end

  test "when an exception is raised" do
    put "/exception_raised.json"

    assert_response 500

    body = JSON.parse(response.body)
    assert_equal("exception...", body["message"])
    assert_equal("internal_server_error", body["status"])
    assert_equal("application/json; charset=utf-8", response.content_type)
  end

  test "using non block syntax" do
    post "/inline_syntax.json"

    assert_response 200

    expected_payload = "{\"a\":{\"nested\":{\"hash\":\"value\"}},\"b\":[4,5,6]}"
    assert_equal(expected_payload, response.body)
    assert_equal("application/json; charset=utf-8", response.content_type)
  end
end
