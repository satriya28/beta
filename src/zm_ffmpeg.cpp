/*
 * ZoneMinder FFMPEG implementation, $Date$, $Revision$
 * Copyright (C) 2001-2008 Philip Coombes
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/ 

#include "zm_ffmpeg.h"
#include "zm_image.h"
#include "zm_rgb.h"

#if HAVE_LIBAVCODEC || HAVE_LIBAVUTIL || HAVE_LIBSWSCALE

void FFMPEGInit() {
  static bool bInit = false;

  if(!bInit) {
    av_register_all();
    av_log_set_level(AV_LOG_DEBUG);
    bInit = true;
  }
}

#if HAVE_LIBAVUTIL
enum _AVPIXELFORMAT GetFFMPEGPixelFormat(unsigned int p_colours, unsigned p_subpixelorder) {
  enum _AVPIXELFORMAT pf;

  Debug(8,"Colours: %d SubpixelOrder: %d",p_colours,p_subpixelorder);

  switch(p_colours) {
    case ZM_COLOUR_RGB24:
    {
    if(p_subpixelorder == ZM_SUBPIX_ORDER_BGR) {
      /* BGR subpixel order */
      pf = AV_PIX_FMT_BGR24;
    } else {
      /* Assume RGB subpixel order */
      pf = AV_PIX_FMT_RGB24;
    }
    break;
    }
    case ZM_COLOUR_RGB32:
    {
    if(p_subpixelorder == ZM_SUBPIX_ORDER_ARGB) {
      /* ARGB subpixel order */
      pf = AV_PIX_FMT_ARGB;
    } else if(p_subpixelorder == ZM_SUBPIX_ORDER_ABGR) {
      /* ABGR subpixel order */
      pf = AV_PIX_FMT_ABGR;
    } else if(p_subpixelorder == ZM_SUBPIX_ORDER_BGRA) {
      /* BGRA subpixel order */
      pf = AV_PIX_FMT_BGRA;
    } else {
      /* Assume RGBA subpixel order */
      pf = AV_PIX_FMT_RGBA;
    }
    break;
    }
    case ZM_COLOUR_GRAY8:
    pf = AV_PIX_FMT_GRAY8;
    break;
    default:
    Panic("Unexpected colours: %d",p_colours);
    pf = AV_PIX_FMT_GRAY8; /* Just to shush gcc variable may be unused warning */
    break;
  }

  return pf;
}
/* The following is copied directly from newer ffmpeg. */
#if LIBAVUTIL_VERSION_CHECK(52, 7, 0, 17, 100)
#else
static int parse_key_value_pair(AVDictionary **pm, const char **buf,
                                const char *key_val_sep, const char *pairs_sep,
                                int flags)
{
    char *key = av_get_token(buf, key_val_sep);
    char *val = NULL;
    int ret;

    if (key && *key && strspn(*buf, key_val_sep)) {
        (*buf)++;
        val = av_get_token(buf, pairs_sep);
    }

    if (key && *key && val && *val)
        ret = av_dict_set(pm, key, val, flags);
    else
        ret = AVERROR(EINVAL);

    av_freep(&key);
    av_freep(&val);

    return ret;
}
int av_dict_parse_string(AVDictionary **pm, const char *str,
                            const char *key_val_sep, const char *pairs_sep,
                            int flags)
   {
       int ret;
   
       if (!str)
          return 0;
   
       /* ignore STRDUP flags */
       flags &= ~(AV_DICT_DONT_STRDUP_KEY | AV_DICT_DONT_STRDUP_VAL);
   
       while (*str) {
           if ((ret = parse_key_value_pair(pm, &str, key_val_sep, pairs_sep, flags)) < 0)
              return ret;
   
           if (*str)
               str++;
       }
   
       return 0;
  }
#endif
#endif // HAVE_LIBAVUTIL

#if HAVE_LIBSWSCALE && HAVE_LIBAVUTIL
SWScale::SWScale() : gotdefaults(false), swscale_ctx(NULL), input_avframe(NULL), output_avframe(NULL) {
  Debug(4,"SWScale object created");

  /* Allocate AVFrame for the input */
#if LIBAVCODEC_VERSION_CHECK(55, 28, 1, 45, 101)
  input_avframe = av_frame_alloc();
#else
  input_avframe = avcodec_alloc_frame();
#endif
  if(input_avframe == NULL) {
    Fatal("Failed allocating AVFrame for the input");
  }

  /* Allocate AVFrame for the output */
#if LIBAVCODEC_VERSION_CHECK(55, 28, 1, 45, 101)
  output_avframe = av_frame_alloc();
#else
  output_avframe = avcodec_alloc_frame();
#endif
  if(output_avframe == NULL) {
    Fatal("Failed allocating AVFrame for the output");
  }
}

SWScale::~SWScale() {

  /* Free up everything */
#if LIBAVCODEC_VERSION_CHECK(55, 28, 1, 45, 101)
  av_frame_free( &input_avframe );
#else
  av_freep( &input_avframe );
#endif   
  //input_avframe = NULL;

#if LIBAVCODEC_VERSION_CHECK(55, 28, 1, 45, 101)
  av_frame_free( &output_avframe );
#else
  av_freep( &output_avframe );
#endif
  //output_avframe = NULL;

  if(swscale_ctx) {
    sws_freeContext(swscale_ctx);
    swscale_ctx = NULL;
  }
  
  Debug(4,"SWScale object destroyed");
}

int SWScale::SetDefaults(enum _AVPIXELFORMAT in_pf, enum _AVPIXELFORMAT out_pf, unsigned int width, unsigned int height) {

  /* Assign the defaults */
  default_input_pf = in_pf;
  default_output_pf = out_pf;
  default_width = width;
  default_height = height;

  gotdefaults = true;

  return 0;
}

int SWScale::Convert(const uint8_t* in_buffer, const size_t in_buffer_size, uint8_t* out_buffer, const size_t out_buffer_size, enum _AVPIXELFORMAT in_pf, enum _AVPIXELFORMAT out_pf, unsigned int width, unsigned int height) {
  /* Parameter checking */
  if(in_buffer == NULL || out_buffer == NULL) {
    Error("NULL Input or output buffer");
    return -1;
  }
  //  if(in_pf == 0 || out_pf == 0) {
  //    Error("Invalid input or output pixel formats");
  //    return -2;
  //  }
  if (!width || !height) {
    Error("Invalid width or height");
    return -3;
  }

#if LIBSWSCALE_VERSION_CHECK(0, 8, 0, 8, 0)
  /* Warn if the input or output pixelformat is not supported */
  if(!sws_isSupportedInput(in_pf)) {
    Warning("swscale does not support the input format: %c%c%c%c",(in_pf)&0xff,((in_pf)&0xff),((in_pf>>16)&0xff),((in_pf>>24)&0xff));
  }
  if(!sws_isSupportedOutput(out_pf)) {
    Warning("swscale does not support the output format: %c%c%c%c",(out_pf)&0xff,((out_pf>>8)&0xff),((out_pf>>16)&0xff),((out_pf>>24)&0xff));
  }
#endif

  /* Check the buffer sizes */
#if LIBAVUTIL_VERSION_CHECK(54, 6, 0, 6, 0)
  size_t insize = av_image_get_buffer_size(in_pf, width, height,1);
#else
  size_t insize = avpicture_get_size(in_pf, width, height);
#endif
  if(insize != in_buffer_size) {
    Error("The input buffer size does not match the expected size for the input format. Required: %d Available: %d", insize, in_buffer_size);
    return -4;
  }
#if LIBAVUTIL_VERSION_CHECK(54, 6, 0, 6, 0)
  size_t outsize = av_image_get_buffer_size(out_pf, width, height,1);
#else
  size_t outsize = avpicture_get_size(out_pf, width, height);
#endif
  if(outsize < out_buffer_size) {
    Error("The output buffer is undersized for the output format. Required: %d Available: %d", outsize, out_buffer_size);
    return -5;
  }

  /* Get the context */
  swscale_ctx = sws_getCachedContext(swscale_ctx, width, height, in_pf, width, height, out_pf, 0, NULL, NULL, NULL);
  if(swscale_ctx == NULL) {
    Error("Failed getting swscale context");
    return -6;
  }

  /* Fill in the buffers */
#if LIBAVUTIL_VERSION_CHECK(54, 6, 0, 6, 0)
  if (av_image_fill_arrays(input_avframe->data, input_avframe->linesize,
                           (uint8_t*) in_buffer, in_pf, width, height, 1) <= 0) {
#else
  if (avpicture_fill((AVPicture*) input_avframe, (uint8_t*) in_buffer,
                     in_pf, width, height) <= 0) {
#endif
    Error("Failed filling input frame with input buffer");
    return -7;
  }
#if LIBAVUTIL_VERSION_CHECK(54, 6, 0, 6, 0)
  if (av_image_fill_arrays(output_avframe->data, output_avframe->linesize,
                           out_buffer, out_pf, width, height, 1) <= 0) {
#else
  if (avpicture_fill((AVPicture*) output_avframe, out_buffer, out_pf, width,
                     height) <= 0) {
#endif
    Error("Failed filling output frame with output buffer");
    return -8;
  }

  /* Do the conversion */
  if(!sws_scale(swscale_ctx, input_avframe->data, input_avframe->linesize, 0, height, output_avframe->data, output_avframe->linesize ) ) {
    Error("swscale conversion failed");
    return -10;
  }

  return 0;
}

int SWScale::Convert(const Image* img, uint8_t* out_buffer, const size_t out_buffer_size, enum _AVPIXELFORMAT in_pf, enum _AVPIXELFORMAT out_pf, unsigned int width, unsigned int height) {
  if(img->Width() != width) {
    Error("Source image width differs. Source: %d Output: %d",img->Width(), width);
    return -12;
  }

  if(img->Height() != height) {
    Error("Source image height differs. Source: %d Output: %d",img->Height(), height);
    return -13;
  }

  return Convert(img->Buffer(),img->Size(),out_buffer,out_buffer_size,in_pf,out_pf,width,height);
}

int SWScale::ConvertDefaults(const Image* img, uint8_t* out_buffer, const size_t out_buffer_size) {

  if(!gotdefaults) {
    Error("Defaults are not set");
    return -24;
  }

  return Convert(img,out_buffer,out_buffer_size,default_input_pf,default_output_pf,default_width,default_height);
}

int SWScale::ConvertDefaults(const uint8_t* in_buffer, const size_t in_buffer_size, uint8_t* out_buffer, const size_t out_buffer_size) {

  if(!gotdefaults) {
    Error("Defaults are not set");
    return -24;
  }

  return Convert(in_buffer,in_buffer_size,out_buffer,out_buffer_size,default_input_pf,default_output_pf,default_width,default_height);
}
#endif // HAVE_LIBSWSCALE && HAVE_LIBAVUTIL


#endif // HAVE_LIBAVCODEC || HAVE_LIBAVUTIL || HAVE_LIBSWSCALE

#if HAVE_LIBAVUTIL
int64_t av_rescale_delta(AVRational in_tb, int64_t in_ts,  AVRational fs_tb, int duration, int64_t *last, AVRational out_tb){
  int64_t a, b, this_thing;

  av_assert0(in_ts != AV_NOPTS_VALUE);
  av_assert0(duration >= 0);

  if (*last == AV_NOPTS_VALUE || !duration || in_tb.num*(int64_t)out_tb.den <= out_tb.num*(int64_t)in_tb.den) {
simple_round:
    *last = av_rescale_q(in_ts, in_tb, fs_tb) + duration;
    return av_rescale_q(in_ts, in_tb, out_tb);
  }

  a =  av_rescale_q_rnd(2*in_ts-1, in_tb, fs_tb, AV_ROUND_DOWN)   >>1;
  b = (av_rescale_q_rnd(2*in_ts+1, in_tb, fs_tb, AV_ROUND_UP  )+1)>>1;
  if (*last < 2*a - b || *last > 2*b - a)
    goto simple_round;

  this_thing = av_clip64(*last, a, b);
  *last = this_thing + duration;

  return av_rescale_q(this_thing, fs_tb, out_tb);
}
#endif

int hacked_up_context2_for_older_ffmpeg(AVFormatContext **avctx, AVOutputFormat *oformat, const char *format, const char *filename) {
  AVFormatContext *s = avformat_alloc_context();
  int ret = 0;

  *avctx = NULL;
  if (!s) {
    av_log(s, AV_LOG_ERROR, "Out of memory\n");
    ret = AVERROR(ENOMEM);
    return ret;
  }

  if (!oformat) {
    if (format) {
      oformat = av_guess_format(format, NULL, NULL);
      if (!oformat) {
        av_log(s, AV_LOG_ERROR, "Requested output format '%s' is not a suitable output format\n", format);
        ret = AVERROR(EINVAL);
      }
    } else {
      oformat = av_guess_format(NULL, filename, NULL);
      if (!oformat) {
        ret = AVERROR(EINVAL);
        av_log(s, AV_LOG_ERROR, "Unable to find a suitable output format for '%s'\n", filename);
      }
    }
  }

  if (ret) {
    avformat_free_context(s);
    return ret;
  } else {
    s->oformat = oformat;
    if (s->oformat->priv_data_size > 0) {
      s->priv_data = av_mallocz(s->oformat->priv_data_size);
      if (s->priv_data) {
        if (s->oformat->priv_class) {
          *(const AVClass**)s->priv_data= s->oformat->priv_class;
          av_opt_set_defaults(s->priv_data);
        }
      } else {
        av_log(s, AV_LOG_ERROR, "Out of memory\n");
        ret = AVERROR(ENOMEM);
        return ret;
      }
      s->priv_data = NULL;
    }

    if (filename) strncpy(s->filename, filename, sizeof(s->filename));
      *avctx = s;
      return 0;
  }
}

static void zm_log_fps(double d, const char *postfix) {
  uint64_t v = lrintf(d * 100);
  if (!v) {
    Debug(3, "%1.4f %s", d, postfix);
  } else if (v % 100) {
    Debug(3, "%3.2f %s", d, postfix);
  } else if (v % (100 * 1000)) {
    Debug(3, "%1.0f %s", d, postfix);
  } else
    Debug(3, "%1.0fk %s", d / 1000, postfix);
}

/* "user interface" functions */
void zm_dump_stream_format(AVFormatContext *ic, int i, int index, int is_output) {
  char buf[256];
  Debug(1, "Dumping stream index i(%d) index(%d)", i, index );
  int flags = (is_output ? ic->oformat->flags : ic->iformat->flags);
  AVStream *st = ic->streams[i];
  AVDictionaryEntry *lang = av_dict_get(st->metadata, "language", NULL, 0);

  avcodec_string(buf, sizeof(buf), st->codec, is_output);
  Debug(3, "    Stream #%d:%d", index, i);

  /* the pid is an important information, so we display it */
  /* XXX: add a generic system */
  if (flags & AVFMT_SHOW_IDS)
    Debug(3, "[0x%x]", st->id);
  if (lang)
    Debug(3, "(%s)", lang->value);
  av_log(NULL, AV_LOG_DEBUG, ", %d, %d/%d", st->codec_info_nb_frames,
        st->time_base.num, st->time_base.den);
  Debug(3, ": %s", buf);

  if (st->sample_aspect_ratio.num && // default
    av_cmp_q(st->sample_aspect_ratio, st->codec->sample_aspect_ratio)) {
    AVRational display_aspect_ratio;
    av_reduce(&display_aspect_ratio.num, &display_aspect_ratio.den,
              st->codec->width  * (int64_t)st->sample_aspect_ratio.num,
              st->codec->height * (int64_t)st->sample_aspect_ratio.den,
              1024 * 1024);
    Debug(3, ", SAR %d:%d DAR %d:%d",
          st->sample_aspect_ratio.num, st->sample_aspect_ratio.den,
          display_aspect_ratio.num, display_aspect_ratio.den);
  }

  if (st->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
    int fps = st->avg_frame_rate.den && st->avg_frame_rate.num;
    int tbn = st->time_base.den && st->time_base.num;
    int tbc = st->codec->time_base.den && st->codec->time_base.num;

    if (fps || tbn || tbc)
      Debug(3, "\n" );

    if (fps)
      zm_log_fps(av_q2d(st->avg_frame_rate), tbn || tbc ? "fps, " : "fps");
    if (tbn)
      zm_log_fps(1 / av_q2d(st->time_base), tbc ? "tbn, " : "tbn");
    if (tbc)
      zm_log_fps(1 / av_q2d(st->codec->time_base), "tbc");
  }

  if (st->disposition & AV_DISPOSITION_DEFAULT)
    Debug(3, " (default)");
  if (st->disposition & AV_DISPOSITION_DUB)
    Debug(3, " (dub)");
  if (st->disposition & AV_DISPOSITION_ORIGINAL)
    Debug(3, " (original)");
  if (st->disposition & AV_DISPOSITION_COMMENT)
    Debug(3, " (comment)");
  if (st->disposition & AV_DISPOSITION_LYRICS)
    Debug(3, " (lyrics)");
  if (st->disposition & AV_DISPOSITION_KARAOKE)
    Debug(3, " (karaoke)");
  if (st->disposition & AV_DISPOSITION_FORCED)
    Debug(3, " (forced)");
  if (st->disposition & AV_DISPOSITION_HEARING_IMPAIRED)
    Debug(3, " (hearing impaired)");
  if (st->disposition & AV_DISPOSITION_VISUAL_IMPAIRED)
    Debug(3, " (visual impaired)");
  if (st->disposition & AV_DISPOSITION_CLEAN_EFFECTS)
    Debug(3, " (clean effects)");
    Debug(3, "\n");

  //dump_metadata(NULL, st->metadata, "    ");

  //dump_sidedata(NULL, st, "    ");
}
