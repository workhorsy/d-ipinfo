

import BDD;

unittest {
	import ipinfo;

	immutable string RESULT = `
	{
	  "ip": "203.205.28.14",
	  "loc": "37.385999999999996,-122.0838",
	  "org": "AS15169 Google Inc.",
	  "city": "Mountain View",
	  "region": "California",
	  "country": "US",
	  "postal": "94043"
	}
	`;

	ipinfo.httpGet = delegate(string url, void delegate(int status, string response) cb) {
		import std.string : startsWith;

		if (url.startsWith("https://ipinfo.io")) {
			cb(200, RESULT);
		}
	};

	describe("ipinfo",
		it("Should get ipinfo", delegate() {
			ipinfo.getIpinfo(delegate(IpinfoData data, Exception err) {
				err.shouldBeNull();

				data.ip.shouldEqual("203.205.28.14");
				data.latitude.shouldEqual("37.385999999999996");
				data.longitude.shouldEqual("-122.0838");
				data.org.shouldEqual("AS15169 Google Inc.");
				data.city.shouldEqual("Mountain View");
				data.region.shouldEqual("California");
				data.country.shouldEqual("US");
				data.postal.shouldEqual("94043");
			});
		}),
		it("Should return an error when failing to parse json response", delegate() {
			httpGet = delegate(string url, void delegate(int status, string response) cb) {
				cb(200, "{");
			};

			ipinfo.getIpinfo(delegate(IpinfoData data, Exception err) {
				err.shouldNotBeNull();
				err.msg.shouldEqual(`Failed to parse "https://ipinfo.io/json" JSON response`);
			});
		}),
		it("Should return an error when the server fails", delegate() {
			httpGet = delegate(string url, void delegate(int status, string response) cb) {
				cb(500, "");
			};

			ipinfo.getIpinfo(delegate(IpinfoData data, Exception err) {
				err.shouldNotBeNull();
				err.msg.shouldEqual(`Request for "https://ipinfo.io/json" failed with status code: 500`);
			});
		}),
	);
}

int main() {
	return BDD.printResults();
}
