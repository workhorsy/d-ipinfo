

import BDD;

unittest {
	import ipinfo;

	immutable string RESULT = `
	{
	  "ip": "8.8.8.8",
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

				data.ip.shouldEqual("8.8.8.8");
				data.latitude.shouldEqual("37.385999999999996");
				data.longitude.shouldEqual("-122.0838");
				data.org.shouldEqual("AS15169 Google Inc.");
				data.city.shouldEqual("Mountain View");
				data.region.shouldEqual("California");
				data.country.shouldEqual("US");
				data.postal.shouldEqual("94043");
			});
		}),
	);
}

int main() {
	return BDD.printResults();
}
