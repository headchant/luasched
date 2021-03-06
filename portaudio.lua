-- set up for port audio using ffi from luajit
-- headchant / henk boom 2012/2013/2014
-- very much inspired by : https://gist.github.com/2871749

local ffi = require 'ffi'

local pa = ffi.load('portaudio')

ffi.cdef [[
int Pa_GetVersion( void );
const char* Pa_GetVersionText( void );
typedef int PaError;
typedef enum PaErrorCode
{
    paNoError = 0,

    paNotInitialized = -10000,
    paUnanticipatedHostError,
    paInvalidChannelCount,
    paInvalidSampleRate,
    paInvalidDevice,
    paInvalidFlag,
    paSampleFormatNotSupported,
    paBadIODeviceCombination,
    paInsufficientMemory,
    paBufferTooBig,
    paBufferTooSmall,
    paNullCallback,
    paBadStreamPtr,
    paTimedOut,
    paInternalError,
    paDeviceUnavailable,
    paIncompatibleHostApiSpecificStreamInfo,
    paStreamIsStopped,
    paStreamIsNotStopped,
    paInputOverflowed,
    paOutputUnderflowed,
    paHostApiNotFound,
    paInvalidHostApi,
    paCanNotReadFromACallbackStream,
    paCanNotWriteToACallbackStream,
    paCanNotReadFromAnOutputOnlyStream,
    paCanNotWriteToAnInputOnlyStream,
    paIncompatibleStreamHostApi,
    paBadBufferPtr
} PaErrorCode;
const char *Pa_GetErrorText( PaError errorCode );
PaError Pa_Initialize( void );
PaError Pa_Terminate( void );

typedef int PaDeviceIndex;
enum
{
    paNoDevice=-1,
    paUseHostApiSpecificDeviceSpecification=-2
};
typedef int PaHostApiIndex;
PaHostApiIndex Pa_GetHostApiCount( void );
PaHostApiIndex Pa_GetDefaultHostApi( void );
typedef enum PaHostApiTypeId
{
    paInDevelopment=0, /* use while developing support for a new host API */
    paDirectSound=1,
    paMME=2,
    paASIO=3,
    paSoundManager=4,
    paCoreAudio=5,
    paOSS=7,
    paALSA=8,
    paAL=9,
    paBeOS=10,
    paWDMKS=11,
    paJACK=12,
    paWASAPI=13,
    paAudioScienceHPI=14
} PaHostApiTypeId;
typedef struct PaHostApiInfo
{
    int structVersion;
    PaHostApiTypeId type;
    const char *name;
    int deviceCount;
    PaDeviceIndex defaultInputDevice;
    PaDeviceIndex defaultOutputDevice;
} PaHostApiInfo;
const PaHostApiInfo * Pa_GetHostApiInfo( PaHostApiIndex hostApi );
PaHostApiIndex Pa_HostApiTypeIdToHostApiIndex( PaHostApiTypeId type );
PaDeviceIndex Pa_HostApiDeviceIndexToDeviceIndex( PaHostApiIndex hostApi,
        int hostApiDeviceIndex );
typedef struct PaHostErrorInfo{
    PaHostApiTypeId hostApiType;    /**< the host API which returned the error code */
    long errorCode;                 /**< the error code returned */
    const char *errorText;          /**< a textual description of the error if available, otherwise a zero-length string */
}PaHostErrorInfo;
const PaHostErrorInfo* Pa_GetLastHostErrorInfo( void );
PaDeviceIndex Pa_GetDeviceCount( void );
PaDeviceIndex Pa_GetDefaultInputDevice( void );
PaDeviceIndex Pa_GetDefaultOutputDevice( void );
typedef double PaTime;
typedef unsigned long PaSampleFormat;

enum
{
    paFloat32        = 0x00000001,
    paInt32          = 0x00000002,
    paInt24          = 0x00000004,
    paInt16          = 0x00000008,
    paInt8           = 0x00000010,
    paUInt8          = 0x00000020,
    paCustomFormat   = 0x00010000,

    paNonInterleaved = 0x80000000
};

typedef struct PaDeviceInfo
{
    int structVersion;
    const char *name;
    PaHostApiIndex hostApi;
    
    int maxInputChannels;
    int maxOutputChannels;

    PaTime defaultLowInputLatency;
    PaTime defaultLowOutputLatency;
    PaTime defaultHighInputLatency;
    PaTime defaultHighOutputLatency;

    double defaultSampleRate;
} PaDeviceInfo;

const PaDeviceInfo* Pa_GetDeviceInfo( PaDeviceIndex device );

typedef struct PaStreamParameters
{
    PaDeviceIndex device;
    int channelCount;
    PaSampleFormat sampleFormat;
    PaTime suggestedLatency;
    void *hostApiSpecificStreamInfo;
} PaStreamParameters;
enum
{
    paFormatIsSupported=0
};
PaError Pa_IsFormatSupported( const PaStreamParameters *inputParameters,
                              const PaStreamParameters *outputParameters,
                              double sampleRate );
typedef void PaStream;
enum
{
    paFramesPerBufferUnspecified=0
};
typedef unsigned long PaStreamFlags;

enum
{
    paNoFlag          = 0,
    paClipOff         = 0x00000001,
    paDitherOff       = 0x00000002,
    paNeverDropInput  = 0x00000004,
    paPrimeOutputBuffersUsingStreamCallback = 0x00000008,
    paPlatformSpecificFlags = 0xFFFF0000
};

typedef struct PaStreamCallbackTimeInfo {
    PaTime inputBufferAdcTime;
    PaTime currentTime;
    PaTime outputBufferDacTime;
} PaStreamCallbackTimeInfo;


typedef unsigned long PaStreamCallbackFlags;
enum
{
    paInputUnderflow  = 0x00000001,
    paInputOverflow   = 0x00000002,
    paOutputUnderflow = 0x00000004,
    paOutputOverflow  = 0x00000008,
    paPrimingOutput   = 0x00000010
};
enum PaStreamCallbackResult
{
    paContinue=0,
    paComplete=1,
    paAbort=2
} PaStreamCallbackResult;
typedef int PaStreamCallback(
    const void *input, void *output,
    unsigned long frameCount,
    const PaStreamCallbackTimeInfo* timeInfo,
    PaStreamCallbackFlags statusFlags,
    void *userData );
PaError Pa_OpenStream( PaStream** stream,
                       const PaStreamParameters *inputParameters,
                       const PaStreamParameters *outputParameters,
                       double sampleRate,
                       unsigned long framesPerBuffer,
                       PaStreamFlags streamFlags,
                       PaStreamCallback *streamCallback,
                       void *userData );
PaError Pa_OpenDefaultStream( PaStream** stream,
                              int numInputChannels,
                              int numOutputChannels,
                              PaSampleFormat sampleFormat,
                              double sampleRate,
                              unsigned long framesPerBuffer,
                              PaStreamCallback *streamCallback,
                              void *userData );
PaError Pa_CloseStream( PaStream *stream );
typedef void PaStreamFinishedCallback( void *userData );
PaError Pa_SetStreamFinishedCallback( PaStream *stream, PaStreamFinishedCallback* streamFinishedCallback ); 
PaError Pa_StartStream( PaStream *stream );
PaError Pa_StopStream( PaStream *stream );
PaError Pa_AbortStream( PaStream *stream );
PaError Pa_IsStreamStopped( PaStream *stream );
PaError Pa_IsStreamActive( PaStream *stream );
typedef struct PaStreamInfo
{
    int structVersion;
    PaTime inputLatency;
    PaTime outputLatency;
    double sampleRate;
} PaStreamInfo;
const PaStreamInfo* Pa_GetStreamInfo( PaStream *stream );
PaTime Pa_GetStreamTime( PaStream *stream );
double Pa_GetStreamCpuLoad( PaStream* stream );
PaError Pa_ReadStream( PaStream* stream,
                       void *buffer,
                       unsigned long frames );
PaError Pa_WriteStream( PaStream* stream,
                        const void *buffer,
                        unsigned long frames );
signed long Pa_GetStreamReadAvailable( PaStream* stream );
signed long Pa_GetStreamWriteAvailable( PaStream* stream );
PaError Pa_GetSampleSize( PaSampleFormat format );
void Pa_Sleep( long msec );
]]

local buffer_size = 2048

local function check_error(err)
  if err == pa.paUnanticipatedHostError then
    assert(false, ffi.string(pa.Pa_GetLastHostErrorInfo().errorText))
  elseif err ~= pa.paNoError then
    assert(false, ffi.string(pa.Pa_GetErrorText(err)))
  end
end

local stream_ptr = ffi.new('PaStream*[1]')

local function init()
  check_error(pa.Pa_Initialize())

  local outputParams = ffi.new('struct PaStreamParameters')
  outputParams.device = pa.Pa_GetDefaultOutputDevice()
  outputParams.channelCount = 1
  outputParams.sampleFormat = pa.paFloat32
  outputParams.suggestedLatency =
    pa.Pa_GetDeviceInfo(outputParams.device).defaultLowOutputLatency
    print("latency", outputParams.suggestedLatency)
    print("buffer size", buffer_size)

  outputParams.hostApiSpecificStreamInfo = nil

  check_error(pa.Pa_OpenStream(
    stream_ptr, nil, outputParams, 44100, buffer_size, 0, nil, nil))

  check_error(pa.Pa_StartStream(stream_ptr[0]))
end

local buffer = ffi.new('float[?]', buffer_size)
local index = 0

local function put_sample(sample)
  buffer[index] = sample
  index = index + 1
  if index == buffer_size then
    index = 0
    -- check_error(pa.Pa_WriteStream(stream_ptr[0], buffer, buffer_size))
    pa.Pa_WriteStream(stream_ptr[0], buffer, buffer_size)
  end
end

local function put_buffer(b)
  for i = 1, buffer_size do
    buffer[i-1] = b[i]
  end
  pa.Pa_WriteStream(stream_ptr[0], buffer, buffer_size)
end

local function uninit()
  check_error(pa.Pa_StopStream(stream_ptr[0]))
  check_error(pa.Pa_CloseStream(stream_ptr[0]))
  pa.Pa_Terminate()
end

return {init = init, put_buffer = put_buffer, put_sample = put_sample, uninit = uninit, buffer_size = buffer_size2}