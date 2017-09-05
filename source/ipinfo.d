// Copyright (c) 2017 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Get http://ipinfo.io info with the D programming language
// https://github.com/workhorsy/d-ipinfo

/++
Get http://ipinfo.io with the D programming language.

Home page:
$(LINK https://github.com/workhorsy/d-ipinfo)

Version: 1.0.0

License:
Boost Software License - Version 1.0

Examples:
----
import std.stdio : stdout;
import ipinfo : getIpinfo, IpinfoData;

getIpinfo(delegate(IpinfoData data) {
	stdout.writefln("ip: %s", data.ip);
	stdout.writefln("latitude: %s", data.latitude);
	stdout.writefln("longitude: %s", data.longitude);
	stdout.writefln("org: %s", data.org);
	stdout.writefln("city: %s", data.city);
	stdout.writefln("region: %s", data.region);
	stdout.writefln("country: %s", data.country);
	stdout.writefln("postal: %s", data.postal);
});
----
+/

module ipinfo;

/++
Data gathered in IpinfoData:
----
struct IpinfoData {
	string ip;
	string latitude;
	string longitude;
	string org;
	string city;
	string region;
	string country;
	string postal;
}
----
+/

struct IpinfoData {
	string ip;
	string latitude;
	string longitude;
	string org;
	string city;
	string region;
	string country;
	string postal;
}

void delegate(string url, void delegate(int status, string response) cb) httpGet;
private void delegate(string url, void delegate(int status, string response) cb) httpGetDefault;

static this() {
	httpGetDefault = delegate(string url, void delegate(int status, string response) cb) {
		import std.stdio : stdout, stderr;
		import std.net.curl : HTTP, CurlException, get;

		auto http = HTTP();
		string content = "";

		try {
			content = cast(string) get(url, http);
		} catch (CurlException ex) {
			stderr.writefln("!!! url: %s", url);
			stderr.writefln("!!! CurlException: %s", ex.msg);
			//stderr.writefln("!!!!!!!!!!!!!!!! CurlException: %s", ex);
		}

		ushort status = http.statusLine().code;
		cb(status, content);
	};

	httpGet = httpGetDefault;
}

/++
Returns the ipinfo info using a callback.

Params:
 cb = The callback to fire when the ipinfo info has been downloaded.
+/
void getIpinfo(void delegate(IpinfoData data) cb) {
	import std.stdio : stdout, stderr;
	import std.json : JSONValue, parseJSON;
	import std.string : chomp;
	import std.array : split;
	import std.conv : to;

	// Get ipinfo for this ip address
	httpGet("https://ipinfo.io/json", delegate(int status, string response) {
		if (status != 200) {
			stderr.writefln("Request for ipinfo data failed with status code: %s", status);
			return;
		}

		IpinfoData data;
		try {
			JSONValue j = parseJSON(response);

			string[] loc = split(j["loc"].str(), ",");

			data.ip = j["ip"].str();
			data.latitude = chomp(loc[0]);
			data.longitude = chomp(loc[1]);
			data.org = j["org"].str();
			data.city = j["city"].str();
			data.region = j["region"].str();
			data.country = j["country"].str();
			data.postal = j["postal"].str();
		} catch (Throwable) {
			stderr.writefln("Failed to parse ipinfo JSON response: %s", response);
			return;
		}

		cb(data);
	});
}

unittest {
	import BDD;

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
			ipinfo.getIpinfo(delegate(IpinfoData data) {
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
