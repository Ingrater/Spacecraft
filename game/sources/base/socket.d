module base.socket;

import thBase.string;
import thBase.casts;
import core.allocator;
import core.refcounted;

/**
 * Patched socket source file. Makes accept() not throw an execption for non
 * blocking sockets. Also provides POSIX error codes that work with WinSocks.
 * 
 * Error codes taken from:
 * - http://msdn.microsoft.com/en-us/library/ms740668(v=vs.85).aspx
 * - http://pubs.opengroup.org/onlinepubs/009695399/functions/recv.html
 */
version(Windows)
	enum { EINTR = 10004, EWOULDBLOCK = 10035, ECONNRESET = 10054 }
else
	enum { EINTR = 4, EWOULDBLOCK = 11, ECONNRESET = 104 }

// Written in the D programming language

/*
        Copyright (C) 2004-2005 Christopher E. Miller

        This software is provided 'as-is', without any express or implied
        warranty.  In no event will the authors be held liable for any damages
        arising from the use of this software.

        Permission is granted to anyone to use this software for any purpose,
        including commercial applications, and to alter it and redistribute it
        freely, subject to the following restrictions:

        1. The origin of this software must not be misrepresented; you must not
           claim that you wrote the original software. If you use this software
           in a product, an acknowledgment in the product documentation would be
           appreciated but is not required.
        2. Altered source versions must be plainly marked as such, and must not
           be misrepresented as being the original software.
        3. This notice may not be removed or altered from any source
           distribution.

        socket.d 1.3
        Jan 2005

        Thanks to Benjamin Herr for his assistance.
*/

/**
 * Notes: For Win32 systems, link with ws2_32.lib.
 * Example: See /dmd/samples/d/listener.d.
 * Authors: Christopher E. Miller
 * Source:  $(PHOBOSSRC std/_socket.d)
 * Macros:
 *      WIKI=Phobos/StdSocket
 */

import core.stdc.stdint, std.c.string, std.c.stdlib,
    std.traits;
import thBase.format;

version(unittest)
{
    private import std.c.stdio : printf;
}

version(Posix)
{
        version = BsdSockets;
}

version(Windows)
{
        pragma (lib, "ws2_32.lib");
        pragma (lib, "wsock32.lib");

        private import std.c.windows.windows, std.c.windows.winsock;
        private alias std.c.windows.winsock.timeval _ctimeval;

        enum socket_t : SOCKET { INVALID_SOCKET = -1 };
        private const int _SOCKET_ERROR = SOCKET_ERROR;


        private int _lasterr()
        {
                return WSAGetLastError();
        }
}
else version(BsdSockets)
{
    version(Posix)
    {
        version(linux)
            import std.c.linux.socket : AF_IPX, AF_APPLETALK, SOCK_RDM,
                IPPROTO_IGMP, IPPROTO_GGP, IPPROTO_PUP, IPPROTO_IDP,
                protoent, servent, hostent, SD_RECEIVE, SD_SEND, SD_BOTH,
                MSG_NOSIGNAL, INADDR_NONE, getprotobyname, getprotobynumber,
                getservbyname, getservbyport, gethostbyname, gethostbyaddr;
        else version(OSX)
            private import std.c.osx.socket;
        else version(FreeBSD)
        {
            import core.sys.posix.sys.socket;
            import core.sys.posix.sys.select;
            import std.c.freebsd.socket;
            private enum SD_RECEIVE = SHUT_RD;
            private enum SD_SEND    = SHUT_WR;
            private enum SD_BOTH    = SHUT_RDWR;
        }
        else
            static assert(false);
        private import core.sys.posix.fcntl;
        private import core.sys.posix.unistd;
        private import core.sys.posix.arpa.inet;
        private import core.sys.posix.netinet.tcp;
        private import core.sys.posix.netinet.in_;
        private import core.sys.posix.sys.time;
        //private import core.sys.posix.sys.select;
        private import core.sys.posix.sys.socket;
        private alias core.sys.posix.sys.time.timeval _ctimeval;
    }
    private import core.stdc.errno;

    enum socket_t : int32_t { init = -1, INVALID_SOCKET = -1 }
    private const int _SOCKET_ERROR = -1;


    private int _lasterr()
    {
        return errno;
    }
}
else
{
        static assert(0); // No socket support yet.
}


/// Base exception thrown from a Socket.
class SocketException: Exception
{
        int errorCode; /// Platform-specific error code.

        this(string msg, int err = 0)
        {
            errorCode = err;

            version(Posix)
            {
                if(errorCode > 0)
                {
                    char[80] buf;
                    const(char)* cs;
                    version (linux)
                    {
                        cs = strerror_r(errorCode, buf.ptr, buf.length);
                    }
                    else version (OSX)
                    {
                        auto errs = strerror_r(errorCode, buf.ptr, buf.length);
                        if (errs == 0)
                            cs = buf.ptr;
                        else
                        {
                            cs = "Unknown error";
                        }
                    }
                    else version (FreeBSD)
                    {
                        auto errs = strerror_r(errorCode, buf.ptr, buf.length);
                        if (errs == 0)
                            cs = buf.ptr;
                        else
                        {
                            cs = "Unknown error";
                        }
                    }
                    else
                    {
                        static assert(0);
                    }

                    auto len = strlen(cs);

                    if(cs[len - 1] == '\n')
                            len--;
                    if(cs[len - 1] == '\r')
                            len--;
                    msg = cast(string) (msg ~ ": " ~ cs[0 .. len]);
                }
            }

            super(msg);
        }
}


shared static this()
{
        version(Windows)
        {
                WSADATA wd;

                // Winsock will still load if an older version is present.
                // The version is just a request.
                int val;
                val = WSAStartup(0x2020, &wd);
                if(val) // Request Winsock 2.2 for IPv6.
                        throw New!SocketException("Unable to initialize socket library", val);
        }
}


shared static ~this()
{
    version(Windows)
    {
            WSACleanup();
    }
}

/**
 * The communication domain used to resolve an address.
 */
enum AddressFamily: int
{
        UNSPEC =     AF_UNSPEC, ///
        UNIX =       AF_UNIX,   /// local communication
        INET =       AF_INET,   /// internet protocol version 4
        IPX =        AF_IPX,    /// novell IPX
        APPLETALK =  AF_APPLETALK,      /// appletalk
        INET6 =      AF_INET6,  // internet protocol version 6
}


/**
 * Communication semantics
 */
enum SocketType: int
{
        STREAM =     SOCK_STREAM,       /// sequenced, reliable, two-way communication-based byte streams
        DGRAM =      SOCK_DGRAM,        /// connectionless, unreliable datagrams with a fixed maximum length; data may be lost or arrive out of order
        RAW =        SOCK_RAW,          /// raw protocol access
        RDM =        SOCK_RDM,          /// reliably-delivered message datagrams
        SEQPACKET =  SOCK_SEQPACKET,    /// sequenced, reliable, two-way connection-based datagrams with a fixed maximum length
}


/**
 * Protocol
 */
enum ProtocolType: int
{
        IP =    IPPROTO_IP,     /// internet protocol version 4
        ICMP =  IPPROTO_ICMP,   /// internet control message protocol
        IGMP =  IPPROTO_IGMP,   /// internet group management protocol
        GGP =   IPPROTO_GGP,    /// gateway to gateway protocol
        TCP =   IPPROTO_TCP,    /// transmission control protocol
        PUP =   IPPROTO_PUP,    /// PARC universal packet protocol
        UDP =   IPPROTO_UDP,    /// user datagram protocol
        IDP =   IPPROTO_IDP,    /// Xerox NS protocol
        IPV6 =  IPPROTO_IPV6,   /// internet protocol version 6
}


/**
 * Protocol is a class for retrieving protocol information.
 */
class Protocol
{
        ProtocolType type;      /// These members are populated when one of the following functions are called without failure:
        rcstring name;            /// ditto
        rcstring[] aliases;       /// ditto

        ~this()
        {
          if(aliases.ptr !is null)
          {
            Delete(aliases.ptr);
            aliases = null;
          }
        }

        void populate(protoent* proto)
        {
                type = cast(ProtocolType)proto.p_proto;
                name = fromCString(proto.p_name);

                int i;
                for(i = 0;; i++)
                {
                        if(!proto.p_aliases[i])
                                break;
                }


                if(aliases.ptr != null)
                {
                  Delete(aliases);
                }
                if(i)
                {
                        aliases = NewArray!rcstring(i);
                        for(i = 0; i != aliases.length; i++)
                        {
                          aliases[i] = fromCString(proto.p_aliases[i]);
                        }
                }
                else
                {
                        aliases = null;
                }
        }

        /** Returns false on failure */
        bool getProtocolByName(string name)
        {
                protoent* proto;
                proto = getprotobyname(toCString(name));
                if(!proto)
                        return false;
                populate(proto);
                return true;
        }


        /** Returns false on failure */
        // Same as getprotobynumber().
        bool getProtocolByType(ProtocolType type)
        {
                protoent* proto;
                proto = getprotobynumber(type);
                if(!proto)
                        return false;
                populate(proto);
                return true;
        }
}


unittest
{
    version (Windows)
    {
        // These fail, don't know why
        pragma(msg, " --- std.socket(" ~ __LINE__.stringof ~ ") broken test ---");
    }
    else
    {
		Protocol proto = new Protocol;
        assert(proto.getProtocolByType(ProtocolType.TCP));
        //printf("About protocol TCP:\n\tName: %.*s\n", proto.name);
        // foreach(string s; proto.aliases)
        // {
        //      printf("\tAlias: %.*s\n", s);
        // }
        assert(proto.name == "tcp");
        assert(proto.aliases.length == 1 && proto.aliases[0] == "TCP");
    }
}


/**
 * Service is a class for retrieving service information.
 */
class Service
{
        /** These members are populated when one of the following functions are called without failure: */
        rcstring name;
        rcstring[] aliases;       /// ditto
        ushort port;            /// ditto
        rcstring protocolName;    /// ditto

        ~this()
        {
          if(aliases.ptr !is null)
          {
            Delete(aliases);
            aliases = null;
          }
        }

        void populate(servent* serv)
        {
                name = fromCString(serv.s_name);
                port = ntohs(cast(ushort)serv.s_port);
                protocolName = fromCString(serv.s_proto);

                int i;
                for(i = 0;; i++)
                {
                        if(!serv.s_aliases[i])
                                break;
                }

                if(aliases.ptr !is null)
                {
                  Delete(aliases);
                }

                if(i)
                {
                        aliases = NewArray!rcstring(i);
                        for(i = 0; i != aliases.length; i++)
                        {
                            aliases[i] = fromCString(serv.s_aliases[i]);
                        }
                }
                else
                {
                        aliases = null;
                }
        }

        /**
         * If a protocol name is omitted, any protocol will be matched.
         * Returns: false on failure.
         */
        bool getServiceByName(string name, string protocolName)
        {
                servent* serv;
                serv = getservbyname(toCString(name), toCString(protocolName));
                if(!serv)
                        return false;
                populate(serv);
                return true;
        }


        // Any protocol name will be matched.
        /// ditto
        bool getServiceByName(string name)
        {
                servent* serv;
                serv = getservbyname(toCString(name), null);
                if(!serv)
                        return false;
                populate(serv);
                return true;
        }


        /// ditto
        bool getServiceByPort(ushort port, string protocolName)
        {
                servent* serv;
                serv = getservbyport(port, toCString(protocolName));
                if(!serv)
                        return false;
                populate(serv);
                return true;
        }


        // Any protocol name will be matched.
        /// ditto
        bool getServiceByPort(ushort port)
        {
                servent* serv;
                serv = getservbyport(port, null);
                if(!serv)
                        return false;
                populate(serv);
                return true;
        }
}


unittest
{
        Service serv = new Service;
        if(serv.getServiceByName("epmap", "tcp"))
        {
                // printf("About service epmap:\n\tService: %.*s\n"
        //         "\tPort: %d\n\tProtocol: %.*s\n",
        //         serv.name, serv.port, serv.protocolName);
                // foreach(string s; serv.aliases)
                // {
                //      printf("\tAlias: %.*s\n", s);
                // }
        // For reasons unknown this is loc-srv on Wine and epmap on Windows
        assert(serv.name == "loc-srv" || serv.name == "epmap", serv.name);
        assert(serv.port == 135);
        assert(serv.protocolName == "tcp");
        // This assert used to pass, don't know why it fails now
        //assert(serv.aliases.length == 1 && serv.aliases[0] == "epmap");
        }
        else
        {
                printf("No service for epmap.\n");
        }
}


/**
 * Base exception thrown from an InternetHost.
 */
class HostException: Exception
{
        int errorCode;  /// Platform-specific error code.


        this(string msg, int err = 0)
        {
                errorCode = err;
                super(msg);
        }
}

/**
 * InternetHost is a class for resolving IPv4 addresses.
 */
class InternetHost
{
        /** These members are populated when one of the following functions are called without failure: */
        rcstring name;
        rcstring[] aliases;       /// ditto
        uint32_t[] addrList;    /// ditto

        ~this()
        {
          if(aliases.ptr !is null)
          {
            Delete(aliases.ptr);
            aliases = null;
          }
          if(addrList.ptr !is null)
          {
            Delete(addrList);
            addrList = null;
          }
        }

        void validHostent(hostent* he)
        {
                if(he.h_addrtype != cast(int)AddressFamily.INET || he.h_length != 4)
                        throw New!HostException("Address family mismatch", _lasterr());
        }


        void populate(hostent* he)
        {
                int i;
                char* p;

                name = fromCString(he.h_name);

                for(i = 0;; i++)
                {
                        p = he.h_aliases[i];
                        if(!p)
                                break;
                }

                if(aliases.ptr !is null)
                {
                  Delete(aliases);
                }

                if(i)
                {
                        aliases = NewArray!rcstring(i);
                        for(i = 0; i != aliases.length; i++)
                        {
                            aliases[i] = fromCString(he.h_aliases[i]);
                        }
                }
                else
                {
                        aliases = null;
                }

                for(i = 0;; i++)
                {
                        p = he.h_addr_list[i];
                        if(!p)
                                break;
                }

                if(addrList.ptr !is null)
                {
                  Delete(addrList);
                }

                if(i)
                {
                        addrList = NewArray!uint32_t(i);
                        for(i = 0; i != addrList.length; i++)
                        {
                                addrList[i] = ntohl(*(cast(uint32_t*)he.h_addr_list[i]));
                        }
                }
                else
                {
                        addrList = null;
                }
        }

        /**
         * Resolve host name. Returns false if unable to resolve.
         */
        bool getHostByName(string name)
        {
                version(Windows)
                {
                    // TODO gethostbyname is deprecated in windows, use getaddrinfo
                    auto he = gethostbyname(toCString(name));
                    if(!he)
                        return false;
                    validHostent(he);
                    populate(he);
                }
                else
                {
                    // posix systems use global state for return value, so we
                    // must synchronize across all threads
                    synchronized(this.classinfo)
                    {
                        auto he = gethostbyname(toStringz(name));
                        if(!he)
                            return false;
                        validHostent(he);
                        populate(he);
                    }
                }
                return true;
        }


        /**
         * Resolve IPv4 address number. Returns false if unable to resolve.
         */
        bool getHostByAddr(uint addr)
        {
                uint x = htonl(addr);
                version(Windows)
                {
                    // TODO gethostbyaddr is deprecated in windows, use getnameinfo
                    auto he = gethostbyaddr(&x, 4, cast(int)AddressFamily.INET);
                    if(!he)
                        return false;
                    validHostent(he);
                    populate(he);
                }
                else
                {
                    // posix systems use global state for return value, so we
                    // must synchronize across all threads
                    synchronized(this.classinfo)
                    {
                        auto he = gethostbyaddr(&x, 4, cast(int)AddressFamily.INET);
                        if(!he)
                            return false;
                        validHostent(he);
                        populate(he);
                    }
                }
                return true;
        }


        /**
         * Same as previous, but addr is an IPv4 address string in the
         * dotted-decimal form $(I a.b.c.d).
         * Returns false if unable to resolve.
         */
        bool getHostByAddr(string addr)
        {
                uint x = inet_addr(toCString(addr));
                version(Windows)
                {
                    // TODO gethostbyaddr is deprecated in windows, use getnameinfo
                    auto he = gethostbyaddr(&x, 4, cast(int)AddressFamily.INET);
                    if(!he)
                        return false;
                    validHostent(he);
                    populate(he);
                }
                else
                {
                    // posix systems use global state for return value, so we
                    // must synchronize across all threads
                    synchronized(this.classinfo)
                    {
                        auto he = gethostbyaddr(&x, 4, cast(int)AddressFamily.INET);
                        if(!he)
                            return false;
                        validHostent(he);
                        populate(he);
                    }
                }
                return true;
        }
}


/+
unittest
{
	version(linux){
		try
		{
			InternetHost ih = new InternetHost;
			if (!ih.getHostByName("www.digitalmars.com"))
				return;             // don't fail if not connected to internet
			//printf("addrList.length = %d\n", ih.addrList.length);
			assert(ih.addrList.length);
			InternetAddress ia = new InternetAddress(ih.addrList[0], InternetAddress.PORT_ANY);
		assert(ih.name == "www.digitalmars.com" || ih.name == "digitalmars.com",
				ih.name);
			// printf("IP address = %.*s\nname = %.*s\n", ia.toAddrString(), ih.name);
			// foreach(int i, string s; ih.aliases)
			// {
			//      printf("aliases[%d] = %.*s\n", i, s);
			// }
			// printf("---\n");

			assert(ih.getHostByAddr(ih.addrList[0]));
			// printf("name = %.*s\n", ih.name);
			// foreach(int i, string s; ih.aliases)
			// {
			//      printf("aliases[%d] = %.*s\n", i, s);
			// }
		}
		catch (Throwable e)
		{
			// Test fails or succeeds depending on environment!
			printf(" --- std.socket(%u) broken test ---\n", __LINE__);
			printf(" (%.*s)\n", e.toString());
		}
	}
}
+/


/**
 * Base exception thrown from an Address.
 */
class AddressException: RCException
{
  this(rcstring msg)
  {
    super(msg);
  }
}


/**
 * Address is an abstract class for representing a network addresses.
 */
abstract class Address : RefCounted
{
        protected sockaddr* name();
        protected int nameLen();
        AddressFamily addressFamily();  /// Family of this address.
        abstract to_string_t toString();             /// Human readable string representing this address.
}

/**
 *
 */
class UnknownAddress: Address
{
        protected:
        sockaddr sa;


        override sockaddr* name()
        {
                return &sa;
        }


        override int nameLen()
        {
                return sa.sizeof;
        }


        public:
        override AddressFamily addressFamily()
        {
                return cast(AddressFamily)sa.sa_family;
        }


        override to_string_t toString()
        {
                return _T("Unknown");
        }
}


/**
 * InternetAddress is a class that represents an IPv4 (internet protocol version
 * 4) address and port.
 */
class InternetAddress : Address
{
        protected:
        sockaddr_in sin;


        override sockaddr* name()
        {
                return cast(sockaddr*)&sin;
        }


        override int nameLen()
        {
                return sin.sizeof;
        }


        public this()
        {
        }


        public:
        const uint ADDR_ANY = INADDR_ANY;       /// Any IPv4 address number.
        const uint ADDR_NONE = INADDR_NONE;     /// An invalid IPv4 address number.
        const ushort PORT_ANY = 0;              /// Any IPv4 port number.

        /// Overridden to return AddressFamily.INET.
        override AddressFamily addressFamily()
        {
                return cast(AddressFamily)AddressFamily.INET;
        }

        /// Returns the IPv4 port number.
        ushort port()
        {
                return ntohs(sin.sin_port);
        }

        /// Returns the IPv4 address number.
        uint addr()
        {
                return ntohl(sin.sin_addr.s_addr);
        }

        /**
         * Params:
         *   addr = an IPv4 address string in the dotted-decimal form a.b.c.d,
         *          or a host name that will be resolved using an InternetHost
         *          object.
         *   port = may be PORT_ANY as stated below.
         */
        public this(string addr, ushort port)
        {
                uint uiaddr = parse(addr);
                if(ADDR_NONE == uiaddr)
                {
                        InternetHost ih = New!InternetHost();
                        scope(exit) Delete(ih);
                        if(!ih.getHostByName(addr))
                                //throw new AddressException("Invalid internet address");
                            throw New!AddressException(format("Unable to resolve host '%s'", addr));
                        uiaddr = ih.addrList[0];
                }
                sin.sin_family = AddressFamily.INET;
                sin.sin_addr.s_addr = htonl(uiaddr);
                sin.sin_port = htons(port);
        }

        /**
         * Construct a new Address. addr may be ADDR_ANY (default) and port may
         * be PORT_ANY, and the actual numbers may not be known until a connection
         * is made.
         */
        public this(uint addr, ushort port)
        {
                sin.sin_family = AddressFamily.INET;
                sin.sin_addr.s_addr = htonl(addr);
                sin.sin_port = htons(port);
        }

        /// ditto
        public this(ushort port)
        {
                sin.sin_family = AddressFamily.INET;
                sin.sin_addr.s_addr = 0; //any, "0.0.0.0"
                sin.sin_port = htons(port);
        }

        /// Human readable string representing the IPv4 address and port in the form $(I a.b.c.d:e).
        override to_string_t toString()
        {
            return format("%s:%d",inet_ntoa(sin.sin_addr),port());
        }

        /**
         * Parse an IPv4 address string in the dotted-decimal form $(I a.b.c.d)
         * and return the number.
         * If the string is not a legitimate IPv4 address,
         * ADDR_NONE is returned.
         */
        static uint parse(string addr)
        {
                return ntohl(inet_addr(toCString(addr)));
        }
}


unittest
{
    try
    {
        SmartPtr!InternetAddress ia = New!InternetAddress("63.105.9.61", 80);
        assert(ia.toString() == "63.105.9.61:80");
    }
    catch (Throwable e)
    {
        printf(" --- std.socket(%u) broken test ---\n", __LINE__);
        printf(" (%.*s)\n", e.toString());
    }
}


/** */
class SocketAcceptException: SocketException
{
        this(string msg, int err = 0)
        {
                super(msg, err);
        }
}

/// How a socket is shutdown:
enum SocketShutdown: int
{
        RECEIVE =  SD_RECEIVE,  /// socket receives are disallowed
        SEND =     SD_SEND,     /// socket sends are disallowed
        BOTH =     SD_BOTH,     /// both RECEIVE and SEND
}


/// Flags may be OR'ed together:
enum SocketFlags: int
{
        NONE =       0,             /// no flags specified

        OOB =        MSG_OOB,       /// out-of-band stream data
        PEEK =       MSG_PEEK,      /// peek at incoming data without removing it from the queue, only for receiving
        DONTROUTE =  MSG_DONTROUTE, /// data should not be subject to routing; this flag may be ignored. Only for sending
       // NOSIGNAL =   MSG_NOSIGNAL,  /// don't send SIGPIPE signal on socket write error and instead return EPIPE
}


/// Duration timeout value.
extern(C) struct timeval
{
        // D interface
        int seconds;            /// Number of seconds.
        int microseconds;       /// Number of additional microseconds.

        // C interface
        deprecated
        {
                alias seconds tv_sec;
                alias microseconds tv_usec;
        }
}


/// A collection of sockets for use with Socket.select.
class SocketSet
{
        private:
        uint maxsockets; /// max desired sockets, the fd_set might be capable of holding more
        fd_set set;


        version(Windows)
        {
                uint count()
                {
                        return set.fd_count;
                }
        }
        else version(BsdSockets)
        {
                int maxfd;
                uint count;
        }


        public:

        /// Set the maximum amount of sockets that may be added.
        this(uint max)
        {
                maxsockets = max;
                reset();
        }

        /// Uses the default maximum for the system.
        this()
        {
                this(FD_SETSIZE);
        }

        /// Reset the SocketSet so that there are 0 Sockets in the collection.
        void reset()
        {
                FD_ZERO(&set);

                version(BsdSockets)
                {
                        maxfd = -1;
                        count = 0;
                }
        }


        void add(socket_t s)
        in
        {
                // Make sure too many sockets don't get added.
                assert(count < maxsockets);
        }
        body
        {
                FD_SET(s, &set);

                version(BsdSockets)
                {
                        ++count;
                        if(s > maxfd)
                                maxfd = s;
                }
        }

        /// Add a Socket to the collection. Adding more than the maximum has dangerous side affects.
        void add(Socket s)
        {
                add(s.sock);
        }

        void remove(socket_t s)
        {
                FD_CLR(s, &set);
                version(BsdSockets)
                {
                        --count;
                        // note: adjusting maxfd would require scanning the set, not worth it
                }
        }


        /// Remove this Socket from the collection.
        void remove(Socket s)
        {
                remove(s.sock);
        }

        int isSet(socket_t s)
        {
                return FD_ISSET(s, &set);
        }


        /// Returns nonzero if this Socket is in the collection.
        int isSet(Socket s)
        {
                return isSet(s.sock);
        }


        /// Return maximum amount of sockets that can be added, like FD_SETSIZE.
        uint max()
        {
                return maxsockets;
        }


        fd_set* toFd_set()
        {
                return &set;
        }


        int selectn()
        {
                version(Windows)
                {
                        return count;
                }
                else version(BsdSockets)
                {
                        return maxfd + 1;
                }
        }
}


/// The level at which a socket option is defined:
enum SocketOptionLevel: int
{
        SOCKET =  SOL_SOCKET,           /// socket level
        IP =      ProtocolType.IP,      /// internet protocol version 4 level
        ICMP =    ProtocolType.ICMP,    ///
        IGMP =    ProtocolType.IGMP,    ///
        GGP =     ProtocolType.GGP,     ///
        TCP =     ProtocolType.TCP,     /// transmission control protocol level
        PUP =     ProtocolType.PUP,     ///
        UDP =     ProtocolType.UDP,     /// user datagram protocol level
        IDP =     ProtocolType.IDP,     ///
        IPV6 =    ProtocolType.IPV6,    /// internet protocol version 6 level
}

/// Linger information for use with SocketOption.LINGER.
extern(C) struct linger
{
        // D interface
        version(Windows)
        {
                uint16_t on;    /// Nonzero for on.
                uint16_t time;  /// Linger time.
        }
        else version(BsdSockets)
        {
                int32_t on;
                int32_t time;
        }

        // C interface
        deprecated
        {
                alias on l_onoff;
                alias time l_linger;
        }
}


/// Specifies a socket option:
enum SocketOption: int
{
        DEBUG =                SO_DEBUG,        /// record debugging information
        BROADCAST =            SO_BROADCAST,    /// allow transmission of broadcast messages
        REUSEADDR =            SO_REUSEADDR,    /// allow local reuse of address
        LINGER =               SO_LINGER,       /// linger on close if unsent data is present
        OOBINLINE =            SO_OOBINLINE,    /// receive out-of-band data in band
        SNDBUF =               SO_SNDBUF,       /// send buffer size
        RCVBUF =               SO_RCVBUF,       /// receive buffer size
        DONTROUTE =            SO_DONTROUTE,    /// do not route

        // SocketOptionLevel.TCP:
        TCP_NODELAY =          .TCP_NODELAY,    /// disable the Nagle algorithm for send coalescing

        // SocketOptionLevel.IPV6:
        IPV6_UNICAST_HOPS =    .IPV6_UNICAST_HOPS,      ///
        IPV6_MULTICAST_IF =    .IPV6_MULTICAST_IF,      ///
        IPV6_MULTICAST_LOOP =  .IPV6_MULTICAST_LOOP,    ///
        IPV6_JOIN_GROUP =      .IPV6_JOIN_GROUP,        ///
        IPV6_LEAVE_GROUP =     .IPV6_LEAVE_GROUP,       ///
}


/**
 *  Socket is a class that creates a network communication endpoint using the
 * Berkeley sockets interface.
 */
class Socket
{
        private:
        socket_t sock;
        AddressFamily _family;

        version(Windows)
            bool _blocking = false;     /// Property to get or set whether the socket is blocking or nonblocking.


        // For use with accepting().
        protected this()
        {
        }


        public:

        /**
         * Create a blocking socket. If a single protocol type exists to support
         * this socket type within the address family, the ProtocolType may be
         * omitted.
         */
        this(AddressFamily af, SocketType type, ProtocolType protocol)
        {
                sock = cast(socket_t)socket(af, type, protocol);
                if(sock == socket_t.INVALID_SOCKET)
                        throw new SocketException("Unable to create socket", _lasterr());
                _family = af;
        }


        // A single protocol exists to support this socket type within the
        // protocol family, so the ProtocolType is assumed.
        /// ditto
        this(AddressFamily af, SocketType type)
        {
                this(af, type, cast(ProtocolType)0); // Pseudo protocol number.
        }


        /// ditto
        this(AddressFamily af, SocketType type, string protocolName)
        {
                protoent* proto;
                proto = getprotobyname(toCString(protocolName));
                if(!proto)
                        throw New!SocketException("Unable to find the protocol", _lasterr());
                this(af, type, cast(ProtocolType)proto.p_proto);
        }


        ~this()
        {
          close();
        }


        /// Get underlying socket handle.
        socket_t handle()
        {
                return sock;
        }
        
				/**
				 * I'm just sick of it... allows anyone to do proper error checking for
				 * nonblocking IO.
				 */
				static int errno(){
					return _lasterr();
				}

        /**
         * Get/set socket's blocking flag.
         *
         * When a socket is blocking, calls to receive(), accept(), and send()
         * will block and wait for data/action.
         * A non-blocking socket will immediately return instead of blocking.
         */
        bool blocking()
        {
                version(Windows)
                {
                        return _blocking;
                }
                else version(BsdSockets)
                {
                        return !(fcntl(handle, F_GETFL, 0) & O_NONBLOCK);
                }
        }

        /// ditto
        void blocking(bool byes)
        {
                version(Windows)
                {
                        uint num = !byes;
                        if(_SOCKET_ERROR == ioctlsocket(sock, FIONBIO, &num))
                                goto err;
                        _blocking = byes;
                }
                else version(BsdSockets)
                {
                        int x = fcntl(sock, F_GETFL, 0);
                        if(-1 == x)
                                goto err;
                        if(byes)
                                x &= ~O_NONBLOCK;
                        else
                                x |= O_NONBLOCK;
                        if(-1 == fcntl(sock, F_SETFL, x))
                                goto err;
                }
                return; // Success.

                err:
                throw new SocketException("Unable to set socket blocking", _lasterr());
        }


        /// Get the socket's address family.
        AddressFamily addressFamily() // getter
        {
                return _family;
        }

        /// Property that indicates if this is a valid, alive socket.
        bool isAlive() // getter
        {
        int type;
        socklen_t typesize = cast(socklen_t) type.sizeof;
                return !getsockopt(sock, SOL_SOCKET, SO_TYPE, cast(char*)&type, &typesize);
        }

        /// Associate a local address with this socket.
        void bind(SmartPtr!Address addr)
        {
                if(_SOCKET_ERROR == .bind(sock, addr.name(), addr.nameLen()))
                        throw New!SocketException("Unable to bind socket", _lasterr());
        }

        /**
         * Establish a connection. If the socket is blocking, connect waits for
         * the connection to be made. If the socket is nonblocking, connect
         * returns immediately and the connection attempt is still in progress.
         */
        void connect(Address to)
        {
                if(_SOCKET_ERROR == .connect(sock, to.name(), to.nameLen()))
                {
                        int err;
                        err = _lasterr();

                        if(!blocking)
                        {
                                version(Windows)
                                {
                                        if(WSAEWOULDBLOCK == err)
                                                return;
                                }
                                else version(Posix)
                                {
                                        if(EINPROGRESS == err)
                                                return;
                                }
                                else
                                {
                                        static assert(0);
                                }
                        }
                        throw new SocketException("Unable to connect socket", err);
                }
        }

        /**
         * Listen for an incoming connection. bind must be called before you can
         * listen. The backlog is a request of how many pending incoming
         * connections are queued until accept'ed.
         */
        void listen(int backlog)
        {
                if(_SOCKET_ERROR == .listen(sock, backlog))
                        throw new SocketException("Unable to listen on socket", _lasterr());
        }

        /**
         * Called by accept when a new Socket must be created for a new
         * connection. To use a derived class, override this method and return an
         * instance of your class. The returned Socket's handle must not be set;
         * Socket has a protected constructor this() to use in this situation.
         */
        // Override to use a derived class.
        // The returned socket's handle must not be set.
        protected Socket accepting()
        {
                return new Socket;
        }

        /**
         * Accept an incoming connection. If the socket is blocking, accept
         * waits for a connection request. Throws SocketAcceptException if unable
         * to accept. See accepting for use with derived classes.
         */
        Socket accept()
        {
                socket_t newsock;
                //newsock = cast(socket_t).accept(sock, null, null); // DMD 0.101 error: found '(' when expecting ';' following 'statement
                alias .accept topaccept;
                newsock = cast(socket_t)topaccept(sock, null, null);
                if(socket_t.INVALID_SOCKET == newsock){
                        // It's ok for nonblocking socket to fail with EWOULDBLOCK
                        auto errno = _lasterr();
                        if(!this.blocking && errno == EWOULDBLOCK)
                          return null;
                        
                        throw new SocketAcceptException("Unable to accept socket connection", _lasterr());
                }

                Socket newSocket;
                try
                {
                        newSocket = accepting();
                        assert(newSocket.sock == socket_t.INVALID_SOCKET);

                        newSocket.sock = newsock;
                        version(Windows)
                                newSocket._blocking = _blocking; //inherits blocking mode
                        newSocket._family = _family; //same family
                }
                catch(Throwable o)
                {
                        _close(newsock);
                        throw o;
                }

                return newSocket;
        }

        /// Disables sends and/or receives.
        void shutdown(SocketShutdown how)
        {
                .shutdown(sock, cast(int)how);
        }


        private static void _close(socket_t sock)
        {
                version(Windows)
                {
                        .closesocket(sock);
                }
                else version(BsdSockets)
                {
                        .close(sock);
                }
        }


        /**
         * Immediately drop any connections and release socket resources.
         * Calling shutdown before close is recommended for connection-oriented
         * sockets. The Socket object is no longer usable after close.
         */
        //calling shutdown() before this is recommended
        //for connection-oriented sockets
        void close()
        {
                _close(sock);
                sock = socket_t.INVALID_SOCKET;
        }


        private SmartPtr!Address newFamilyObject()
        {
                SmartPtr!Address result;
                switch(_family)
                {
                        case cast(AddressFamily)AddressFamily.INET:
                                result = New!InternetAddress();
                                break;

                        default:
                                result = New!UnknownAddress();
                }
                return result;
        }


        /// Returns the local machine's host name. Idea from mango.
        static rcstring hostName() // getter
        {
                char[256] result; // Host names are limited to 255 chars.
                if(_SOCKET_ERROR == .gethostname(result.ptr, result.length))
                        throw New!SocketException("Unable to obtain host name", _lasterr());
                return fromCString(result.ptr);
        }

        /// Remote endpoint Address.
        SmartPtr!Address remoteAddress()
        {
                SmartPtr!Address addr = newFamilyObject();
                socklen_t nameLen = cast(socklen_t) addr.nameLen();
                if(_SOCKET_ERROR == .getpeername(sock, addr.name(), &nameLen))
                        throw New!SocketException("Unable to obtain remote socket address", _lasterr());
                assert(addr.addressFamily() == _family);
                return addr;
        }

        /// Local endpoint Address.
        SmartPtr!Address localAddress()
        {
                SmartPtr!Address addr = newFamilyObject();
                socklen_t nameLen = cast(socklen_t) addr.nameLen();
                if(_SOCKET_ERROR == .getsockname(sock, addr.name(), &nameLen))
                        throw New!SocketException("Unable to obtain local socket address", _lasterr());
                assert(addr.addressFamily() == _family);
                return addr;
        }

        /// Send or receive error code.
        const int ERROR = _SOCKET_ERROR;

        /**
         * Send data on the connection. Returns the number of bytes actually
         * sent, or ERROR on failure. If the socket is blocking and there is no
         * buffer space left, send waits.
         */
        //returns number of bytes actually sent, or -1 on error
        Select!(size_t.sizeof > 4, long, int)
    send(const(void)[] buf, SocketFlags flags)
        {
        static if(is(typeof(MSG_NOSIGNAL)))
        {
          flags |= MSG_NOSIGNAL;
        }
        auto sent = .send(sock, buf.ptr, int_cast!int(buf.length), cast(int)flags);
                return sent;
        }

        /// ditto
        Select!(size_t.sizeof > 4, long, int) send(const(void)[] buf)
        {
          static if(is(typeof(MSG_NOSIGNAL)))
          {
            return send(buf, SocketFlags.NOSIGNAL);
          }
          else
          {
            return send(buf, SocketFlags.NONE);
          }
        }

        /**
         * Send data to a specific destination Address. If the destination address is not specified, a connection must have been made and that address is used. If the socket is blocking and there is no buffer space left, sendTo waits.
         */
        Select!(size_t.sizeof > 4, long, int)
    sendTo(const(void)[] buf, SocketFlags flags, Address to)
        {
        static if(is(typeof(MSG_NOSIGNAL)))
        {
          flags |= SocketFlags.NOSIGNAL;
        }
        return .sendto(sock, buf.ptr, int_cast!int(buf.length), cast(int)flags, to.name(), to.nameLen());
        }

        /// ditto
        Select!(size_t.sizeof > 4, long, int) sendTo(const(void)[] buf, Address to)
        {
                return sendTo(buf, SocketFlags.NONE, to);
        }


        //assumes you connect()ed
        /// ditto
        Select!(size_t.sizeof > 4, long, int) sendTo(const(void)[] buf, SocketFlags flags)
        {
          static if(is(typeof(MSG_NOSIGNAL)))
          {
            flags |= MSG_NOSIGNAL;
          }
          return .sendto(sock, buf.ptr, int_cast!int(buf.length), cast(int)flags, null, 0);
        }


        //assumes you connect()ed
        /// ditto
        Select!(size_t.sizeof > 4, long, int) sendTo(const(void)[] buf)
        {
                return sendTo(buf, SocketFlags.NONE);
        }


        /**
         * Receive data on the connection. Returns the number of bytes actually
         * received, 0 if the remote side has closed the connection, or ERROR on
         * failure. If the socket is blocking, receive waits until there is data
         * to be received.
         */
        //returns number of bytes actually received, 0 on connection closure, or -1 on error
    ptrdiff_t receive(void[] buf, SocketFlags flags)
        {
        return buf.length
            ? .recv(sock, buf.ptr, int_cast!int(buf.length), cast(int)flags)
            : 0;
        }

        /// ditto
        ptrdiff_t receive(void[] buf)
        {
                return receive(buf, SocketFlags.NONE);
        }

        /**
         * Receive data and get the remote endpoint Address.
         * If the socket is blocking, receiveFrom waits until there is data to
         * be received.
         * Returns: the number of bytes actually received,
         * 0 if the remote side has closed the connection, or ERROR on failure.
         */
        Select!(size_t.sizeof > 4, long, int)
    receiveFrom(void[] buf, SocketFlags flags, ref SmartPtr!Address from)
        {
                if(!buf.length) //return 0 and don't think the connection closed
                        return 0;
                from = newFamilyObject();
                socklen_t nameLen = cast(socklen_t) from.nameLen();
                auto read = .recvfrom(sock, buf.ptr, int_cast!int(buf.length), cast(int)flags, from.name(), &nameLen);
                assert(from.addressFamily() == _family);
                // if(!read) //connection closed
                return read;
        }


        /// ditto
        ptrdiff_t receiveFrom(void[] buf, ref SmartPtr!Address from)
        {
                return receiveFrom(buf, SocketFlags.NONE, from);
        }


        //assumes you connect()ed
        /// ditto
        Select!(size_t.sizeof > 4, long, int)
    receiveFrom(void[] buf, SocketFlags flags)
        {
                if(!buf.length) //return 0 and don't think the connection closed
                        return 0;
                auto read = .recvfrom(sock, buf.ptr, int_cast!int(buf.length), cast(int)flags, null, null);
                // if(!read) //connection closed
                return read;
        }


        //assumes you connect()ed
        /// ditto
        ptrdiff_t receiveFrom(void[] buf)
        {
                return receiveFrom(buf, SocketFlags.NONE);
        }


        /// Get a socket option. Returns the number of bytes written to result.
        //returns the length, in bytes, of the actual result - very different from getsockopt()
        int getOption(SocketOptionLevel level, SocketOption option, void[] result)
        {
                socklen_t len = cast(socklen_t) result.length;
                if(_SOCKET_ERROR == .getsockopt(sock, cast(int)level, cast(int)option, result.ptr, &len))
                        throw new SocketException("Unable to get socket option", _lasterr());
                return len;
        }


        /// Common case of getting integer and boolean options.
        int getOption(SocketOptionLevel level, SocketOption option, out int32_t result)
        {
                return getOption(level, option, (&result)[0 .. 1]);
        }


        /// Get the linger option.
        int getOption(SocketOptionLevel level, SocketOption option, out linger result)
        {
                //return getOption(cast(SocketOptionLevel)SocketOptionLevel.SOCKET, SocketOption.LINGER, (&result)[0 .. 1]);
                return getOption(level, option, (&result)[0 .. 1]);
        }

        // Set a socket option.
        void setOption(SocketOptionLevel level, SocketOption option, void[] value)
        {
                if(_SOCKET_ERROR == .setsockopt(sock, cast(int)level,
                        cast(int)option, value.ptr, cast(uint) value.length))
                        throw new SocketException("Unable to set socket option", _lasterr());
        }


        /// Common case for setting integer and boolean options.
        void setOption(SocketOptionLevel level, SocketOption option, int32_t value)
        {
                setOption(level, option, (&value)[0 .. 1]);
        }


        /// Set the linger option.
        void setOption(SocketOptionLevel level, SocketOption option, linger value)
        {
                //setOption(cast(SocketOptionLevel)SocketOptionLevel.SOCKET, SocketOption.LINGER, (&value)[0 .. 1]);
                setOption(level, option, (&value)[0 .. 1]);
        }


        /**
         * Wait for a socket to change status. A wait timeout timeval or int microseconds may be specified; if a timeout is not specified or the timeval is null, the maximum timeout is used. The timeval timeout has an unspecified value when select returns. Returns the number of sockets with status changes, 0 on timeout, or -1 on interruption. If the return value is greater than 0, the SocketSets are updated to only contain the sockets having status changes. For a connecting socket, a write status change means the connection is established and it's able to send. For a listening socket, a read status change means there is an incoming connection request and it's able to accept.
         */
        //SocketSet's updated to include only those sockets which an event occured
        //returns the number of events, 0 on timeout, or -1 on interruption
        //for a connect()ing socket, writeability means connected
        //for a listen()ing socket, readability means listening
        //Winsock: possibly internally limited to 64 sockets per set
        static int select(SocketSet checkRead, SocketSet checkWrite, SocketSet checkError, timeval* tv)
        in
        {
                //make sure none of the SocketSet's are the same object
                if(checkRead)
                {
                        assert(checkRead !is checkWrite);
                        assert(checkRead !is checkError);
                }
                if(checkWrite)
                {
                        assert(checkWrite !is checkError);
                }
        }
        body
        {
                fd_set* fr, fw, fe;
                int n = 0;

                version(Windows)
                {
                        // Windows has a problem with empty fd_set`s that aren't null.
                        fr = (checkRead && checkRead.count()) ? checkRead.toFd_set() : null;
                        fw = (checkWrite && checkWrite.count()) ? checkWrite.toFd_set() : null;
                        fe = (checkError && checkError.count()) ? checkError.toFd_set() : null;
                }
                else
                {
                        if(checkRead)
                        {
                                fr = checkRead.toFd_set();
                                n = checkRead.selectn();
                        }
                        else
                        {
                                fr = null;
                        }

                        if(checkWrite)
                        {
                                fw = checkWrite.toFd_set();
                                int _n;
                                _n = checkWrite.selectn();
                                if(_n > n)
                                        n = _n;
                        }
                        else
                        {
                                fw = null;
                        }

                        if(checkError)
                        {
                                fe = checkError.toFd_set();
                                int _n;
                                _n = checkError.selectn();
                                if(_n > n)
                                        n = _n;
                        }
                        else
                        {
                                fe = null;
                        }
                }

                int result = .select(n, fr, fw, fe, cast(_ctimeval*)tv);

                version(Windows)
                {
                        if(_SOCKET_ERROR == result && WSAGetLastError() == WSAEINTR)
                                return -1;
                }
                else version(Posix)
                {
                        if(_SOCKET_ERROR == result && errno == EINTR)
                                return -1;
                }
                else
                {
                        static assert(0);
                }

                if(_SOCKET_ERROR == result)
                        throw new SocketException("Socket select error", _lasterr());

                return result;
        }


        /// ditto
        static int select(SocketSet checkRead, SocketSet checkWrite, SocketSet checkError, int microseconds)
        {
            timeval tv;
            tv.seconds = microseconds / 1_000_000;
            tv.microseconds = microseconds % 1_000_000;
            return select(checkRead, checkWrite, checkError, &tv);
        }


        /// ditto
        //maximum timeout
        static int select(SocketSet checkRead, SocketSet checkWrite, SocketSet checkError)
        {
                return select(checkRead, checkWrite, checkError, null);
        }


        /+
        bool poll(events)
        {
                int WSAEventSelect(socket_t s, WSAEVENT hEventObject, int lNetworkEvents); // Winsock 2 ?
                int poll(pollfd* fds, int nfds, int timeout); // Unix ?
        }
        +/
}


/// TcpSocket is a shortcut class for a TCP Socket.
class TcpSocket: Socket
{
        /// Constructs a blocking TCP Socket.
        this(AddressFamily family)
        {
                super(family, SocketType.STREAM, ProtocolType.TCP);
        }

        /// Constructs a blocking TCP Socket.
        this()
        {
                this(cast(AddressFamily)AddressFamily.INET);
        }


        //shortcut
        /// Constructs a blocking TCP Socket and connects to an InternetAddress.
        this(Address connectTo)
        {
                this(connectTo.addressFamily());
                connect(connectTo);
        }
}


/// UdpSocket is a shortcut class for a UDP Socket.
class UdpSocket: Socket
{
        /// Constructs a blocking UDP Socket.
        this(AddressFamily family)
        {
                super(family, SocketType.DGRAM, ProtocolType.UDP);
        }


        /// Constructs a blocking UDP Socket.
        this()
        {
                this(cast(AddressFamily)AddressFamily.INET);
        }
}
