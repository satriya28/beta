#ifndef ZM_CMAKE_CONFIG_H
#define ZM_CMAKE_CONFIG_H

/* This file is used by cmake to create config.h for ZM */

/* General system checks */
/* #undef BSD */
/* #undef SOLARIS */
/* #undef HAVE_LINUX_VIDEODEV_H */
#define HAVE_LIBV4L1_VIDEODEV_H 1
#define HAVE_LINUX_VIDEODEV2_H 1
#define HAVE_EXECINFO_H 1
#define HAVE_UCONTEXT_H 1
#define HAVE_SYS_SENDFILE_H 1
#define HAVE_SYS_SYSCALL_H 1
#define HAVE_SYSCALL 1
#define HAVE_SENDFILE 1
#define HAVE_DECL_BACKTRACE 1
#define HAVE_DECL_BACKTRACE_SYMBOLS 1
#define HAVE_POSIX_MEMALIGN 1
#define HAVE_SIGINFO_T 1
#define HAVE_UCONTEXT_T 1

/* Library checks and their header files */
#define HAVE_LIBZLIB 1
#define HAVE_ZLIB_H 1
#define HAVE_LIBCURL 1
#define HAVE_CURL_CURL_H 1
#define HAVE_LIBJPEG 1
#define HAVE_JPEGLIB_H 1
#define HAVE_LIBOPENSSL 1
#define HAVE_OPENSSL_MD5_H 1
#define HAVE_LIBCRYPTO 1
#define HAVE_LIBPTHREAD 1
#define HAVE_PTHREAD_H
#define HAVE_LIBPCRE 1
#define HAVE_PCRE_H 1
#define HAVE_LIBGCRYPT 1
/* #undef HAVE_GCRYPT_H */
#define HAVE_LIBGNUTLS 1
/* #undef HAVE_GNUTLS_OPENSSL_H */
#define HAVE_GNUTLS_GNUTLS_H 1
#define HAVE_LIBMYSQLCLIENT 1
#define HAVE_MYSQL_H 1
#define HAVE_LIBX264 1
#define HAVE_X264_H 1
#define HAVE_LIBMP4V2 1
#define HAVE_MP4V2_MP4V2_H 1
/* #undef HAVE_MP4V2_H */
/* #undef HAVE_MP4_H */
#define HAVE_LIBAVFORMAT 1
#define HAVE_LIBAVFORMAT_AVFORMAT_H 1
#define HAVE_LIBAVCODEC 1
#define HAVE_LIBAVCODEC_AVCODEC_H 1
#define HAVE_LIBAVDEVICE 1
#define HAVE_LIBAVDEVICE_AVDEVICE_H 1
#define HAVE_LIBAVUTIL 1
#define HAVE_LIBAVUTIL_AVUTIL_H 1
#define HAVE_LIBAVUTIL_MATHEMATICS_H 1
#define HAVE_LIBSWSCALE 1
#define HAVE_LIBSWSCALE_SWSCALE_H 1
#define HAVE_LIBVLC 1
#define HAVE_VLC_VLC_H 1

/* Authenication checks */
#define HAVE_MD5_OPENSSL 1
#define HAVE_MD5_GNUTLS 1
#define HAVE_DECL_MD5 1
#define HAVE_DECL_GNUTLS_FINGERPRINT 1

/* Few ZM options that are needed by the source code */
#define ZM_MEM_MAPPED 1

/* Its safe to assume that signal return type is void. This is a fix for zm_signal.h */
#define RETSIGTYPE void

#endif
