# DelayedLauncher

Speed up your Mac's login time by delaying the launch of OS X login items. Makes fine-tuned, stacked delays possible.

## Initial Open Source notes

This code is old, and it was thrown together rather sloppily (the first version was whipped up in a single day).

I never thought I'd be open sourcing it, and I never expected it to be as popular as it got ([LifeHacker!](http://lifehacker.com/delayedlauncher-delays-the-startup-time-of-login-items-506597597)).

I've decided to open source it because I don't have the time to maintain it.

To whomever picks it up, I have the following suggestions:

- Clean up my ugly & rushed code.
- Use [TECommon](https://github.com/taoeffect/TECommon) instead of `Common.h`.
- Use [TERecord](https://github.com/taoeffect/TERecord) instead of `NSMutableDictionaries`.
- Switch to ARC and Objective-C 2+.
- Give it a nice website.
- Talk to me if you have any questions. I'm [easy to get in touch with](http://dns.dnschain.net/id/greg).

## License

BSD-3-Clause:

    Copyright (c) 2013-2014, Greg Slepak
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors
    may be used to endorse or promote products derived from this software without
    specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
