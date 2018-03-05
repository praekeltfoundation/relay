%% We need to muck about inside certs to extract the domains they're valid for,
%% and it's difficult to do that from Elixir with all the nested records and
%% magic number macros involved. To avoid all that, we just do this bit in
%% Erlang and call it from our Elixir code.

-module(pk_utils).

-include_lib("public_key/include/public_key.hrl").

-export([
         get_cert_names/1,
         get_end_entity_certs/1
        ]).


%% Get a list of names (subject CNs and SAN DNS names) for a certificate,
%% decoding it first if necessary.
get_cert_names({'Certificate', CertBinary, not_encrypted}) ->
    get_cert_names(public_key:pkix_decode_cert(CertBinary, otp));
get_cert_names(#'OTPCertificate'{tbsCertificate = TbsCert}) ->
    get_subject_CNs(TbsCert) ++ get_SAN_DNSNames(TbsCert).


%% Get a list of end-entity certs from a list of PEM objects.
get_end_entity_certs(PEM_things) ->
    lists:filter(fun get_end_entity_cert/1, PEM_things).


get_end_entity_cert({'Certificate', CertBinary, not_encrypted}) ->
    OtpCert = public_key:pkix_decode_cert(CertBinary, otp),
    TbsCert = OtpCert #'OTPCertificate'.tbsCertificate,
    Extensions = TbsCert#'OTPTBSCertificate'.extensions,
    BC = pubkey_cert:select_extension(?'id-ce-basicConstraints', Extensions),
    case BC of
        #'Extension'{extnValue = #'BasicConstraints'{cA = false}} -> true;
        _ -> false
    end;
get_end_entity_cert(_) ->
    false.


get_SAN_DNSNames(#'OTPTBSCertificate'{extensions = Extensions}) ->
    SAN = pubkey_cert:select_extension(?'id-ce-subjectAltName', Extensions),
    extract_DNSNames(SAN).


extract_DNSNames(#'Extension'{extnValue = AltNames}) ->
    [DNSName || {dNSName, DNSName} <- AltNames];
extract_DNSNames(_) ->
    [].


get_subject_CNs(#'OTPTBSCertificate'{subject = {rdnSequence, RDNSeq}}) ->
    lists:flatmap(fun extract_CNs/1, RDNSeq).


extract_CNs(RDN) ->
    [CN || #'AttributeTypeAndValue'{type = ?'id-at-commonName',
                                    value = {_, CN}} <- RDN].
