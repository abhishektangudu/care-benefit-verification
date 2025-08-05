/**
 * @description Mock HTTP response generator for testing
 */
@isTest
public class MockHttpResponseGenerator implements HttpCalloutMock {
    private Integer statusCode;
    private String status;
    private String body;

    public MockHttpResponseGenerator(Integer code, String stat, String b) {
        this.statusCode = code;
        this.status = stat;
        this.body = b;
    }

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(this.body);
        res.setStatusCode(this.statusCode);
        res.setStatus(this.status);
        return res;
    }
}