//
// ZoneMinder Ffmpeg Class Interface, $Date: 2008-07-25 10:33:23 +0100 (Fri, 25 Jul 2008) $, $Revision: 2611 $
// Copyright (C) 2001-2008 Philip Coombes
// 
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
// 

#ifndef ZM_FFMPEG_CAMERA_H
#define ZM_FFMPEG_CAMERA_H

#include "zm_camera.h"

#include "zm_buffer.h"
//#include "zm_utils.h"
#include "zm_ffmpeg.h"
#include "zm_videostore.h"

//
// Class representing 'ffmpeg' cameras, i.e. those which are
// accessed using ffmpeg multimedia framework
//
class FfmpegCamera : public Camera
{
protected:
  std::string     mPath;
  std::string      mMethod;
  std::string      mOptions;

  int frameCount;  

#if HAVE_LIBAVFORMAT
  AVFormatContext   *mFormatContext;
  int               mVideoStreamId;
  int               mAudioStreamId;
  AVCodecContext    *mCodecContext;
  AVCodec           *mCodec;
  AVFrame           *mRawFrame; 
  AVFrame           *mFrame;
  _AVPIXELFORMAT    imagePixFormat;

  int OpenFfmpeg();
  int ReopenFfmpeg();
  int CloseFfmpeg();
  static int FfmpegInterruptCallback(void *ctx);
  static void* ReopenFfmpegThreadCallback(void *ctx);
  bool mIsOpening;
  bool mCanCapture;
  int mOpenStart;
  pthread_t mReopenThread;
#endif // HAVE_LIBAVFORMAT

  bool              wasRecording;
  VideoStore        *videoStore;
  char              oldDirectory[4096];
  //AVPacket        lastKeyframePkt;

#if HAVE_LIBSWSCALE
  struct SwsContext   *mConvertContext;
#endif

  int64_t           startTime;

public:
  FfmpegCamera( int p_id, const std::string &path, const std::string &p_method, const std::string &p_options, int p_width, int p_height, int p_colours, int p_brightness, int p_contrast, int p_hue, int p_colour, bool p_capture, bool p_record_audio );
  ~FfmpegCamera();

  const std::string &Path() const { return( mPath ); }
  const std::string &Options() const { return( mOptions ); } 
  const std::string &Method() const { return( mMethod ); }

  void Initialise();
  void Terminate();

  int PrimeCapture();
  int PreCapture();
  int Capture( Image &image );
  int CaptureAndRecord( Image &image, bool recording, char* event_directory );
  int PostCapture();
};

#endif // ZM_FFMPEG_CAMERA_H
