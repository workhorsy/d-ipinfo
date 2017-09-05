


int main() {
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

	return 0;
}