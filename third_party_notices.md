# Third-party notices

FaceSnap and this repository gratefully build on open-source software.

## Redistributed binaries in [`library/`](library)

### gRPC for .NET — `Grpc.Net.Client.dll`, `Grpc.Net.Common.dll`, `Grpc.Core.Api.dll`

Copyright © the gRPC authors ([grpc/grpc-dotnet](https://github.com/grpc/grpc-dotnet)).
Licensed under the [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).

### Protocol Buffers — `Google.Protobuf.dll`

Copyright © Google Inc.
([protocolbuffers/protobuf](https://github.com/protocolbuffers/protobuf)).
Licensed under the BSD 3-Clause License:

> Redistribution and use in source and binary forms, with or without
> modification, are permitted provided that the following conditions are met:
>
> 1. Redistributions of source code must retain the above copyright notice, this
>    list of conditions and the following disclaimer.
> 2. Redistributions in binary form must reproduce the above copyright notice,
>    this list of conditions and the following disclaimer in the documentation
>    and/or other materials provided with the distribution.
> 3. Neither the name of the copyright holder nor the names of its contributors
>    may be used to endorse or promote products derived from this software
>    without specific prior written permission.
>
> THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
> AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
> IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
> DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
> FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
> DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
> SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
> CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
> OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
> OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

### `Microsoft.Extensions.Logging.Abstractions.dll`

Copyright © .NET Foundation and Contributors
([dotnet/runtime](https://github.com/dotnet/runtime)).
Licensed under the [MIT License](https://github.com/dotnet/runtime/blob/main/LICENSE.TXT).

## Open-source software used by the applications

- [.NET](https://dotnet.microsoft.com/) (MIT) — the C# sample and the SDK
- [Flutter](https://flutter.dev/) and [Dart](https://dart.dev/) (BSD 3-Clause) —
  the operator app
- Dart packages: [grpc](https://pub.dev/packages/grpc) (Apache-2.0),
  [protobuf](https://pub.dev/packages/protobuf) (BSD 3-Clause),
  [dartssh2](https://pub.dev/packages/dartssh2) (MIT),
  [file_selector](https://pub.dev/packages/file_selector) (BSD 3-Clause),
  [photo_view](https://pub.dev/packages/photo_view) (MIT),
  [flutter_colorpicker](https://pub.dev/packages/flutter_colorpicker) (MIT)

The FaceSnap kiosk server itself also builds on open source — among others .NET,
OpenCV, MediaPipe, gRPC and Protocol Buffers — under their respective licenses.
