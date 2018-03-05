%% We need to muck about inside certs to extract the domains they're valid for,
%% and it's difficult to do that from Elixir with all the nested records and
%% magic number macros involved. To avoid all that, we just do this bit in
%% Erlang and call it from our Elixir code.

-module(pk_utils).

-include_lib("public_key/include/public_key.hrl").

-export([get_cert_names/1]).


%% Get a list of names (subject CNs and SAN DNS names) for a certificate,
%% decoding it first if necessary.
get_cert_names({'Certificate', CertBinary, not_encrypted}) ->
    get_cert_names(public_key:pkix_decode_cert(CertBinary, otp));
get_cert_names(#'OTPCertificate'{tbsCertificate = TbsCert}) ->
    get_subject_CNs(TbsCert) ++ get_SAN_DNSNames(TbsCert).


get_SAN_DNSNames(#'OTPTBSCertificate'{extensions = Extensions}) ->
    SAN = pubkey_cert:select_extension(?'id-ce-subjectAltName', Extensions),
    extract_DNSNames(SAN).


extract_DNSNames(#'Extension'{extnValue = AltNames}) ->
    [DNSName || {dNSName, DNSName} <- AltNames];
extract_DNSNames(_) ->
    [].


get_subject_CNs(#'OTPTBSCertificate'{subject = {rdnSequence, RDNSeq}}) ->
    lists:flatmap(fun extract_CNs/1, RDNSeq);
get_subject_CNs(#'OTPTBSCertificate'{}) ->
    [].


extract_CNs(RDN) ->
    [CN || #'AttributeTypeAndValue'{type = ?'id-at-commonName',
                                    value = {_, CN}} <- RDN].
