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
import std.stdio : stdout, stderr;
import ipinfo : getIpinfo, IpinfoData;

getIpinfo(delegate(IpinfoData data, Exception err) {
	if (err) {
		stderr.writefln("%s", err);
	} else {
		stdout.writefln("ip: %s", data.ip);
		stdout.writefln("latitude: %s", data.latitude);
		stdout.writefln("longitude: %s", data.longitude);
		stdout.writefln("org: %s", data.org);
		stdout.writefln("city: %s", data.city);
		stdout.writefln("region: %s", data.region);
		stdout.writefln("country: %s", data.country);
		stdout.writefln("postal: %s", data.postal);
	}
});

/*
ip: 8.8.8.8
latitude: 37.385999999999996
longitude: -122.0838
org: AS15169 Google Inc.
city: Indio
region: California
country: US
postal: 94043
*/
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
		import std.net.curl : HTTP, CurlException, get;

		auto http = HTTP();
		string content = "";

		try {
			content = cast(string) get(url, http);
		} catch (CurlException ex) {
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

Throws:
	If it fails to download or parse the JSON response.
+/
void getIpinfo(void delegate(IpinfoData data, Exception err) cb) {
	import std.json : JSONValue, parseJSON;
	import std.string : chomp, format;
	import std.array : split;

	IpinfoData data;
	immutable string URL = "https://ipinfo.io/json";

	// Get ipinfo for this ip address
	httpGet(URL, delegate(int status, string response) {
		if (status != 200) {
			auto err = new Exception("Request for \"%s\" failed with status code: %s".format(URL, status));
			cb(data, err);
			return;
		}

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
			auto err = new Exception("Failed to parse \"%s\" JSON response".format(URL));
			cb(data, err);
			return;
		}

		cb(data, null);
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
