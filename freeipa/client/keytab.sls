{%- from "freeipa/map.jinja" import client, ipa_host with context %}
{%- if client.enabled %}

include:
  - freeipa.client

{%- for keytab_file, keytab in client.get("keytab", {}).iteritems() %}

freeipa_keytab_{{ keytab_file }}:
  file.managed:
    - name: {{ keytab_file }}
    - mode: {{ keytab.get("mode", 0600) }}
    - user: {{ keytab.get("user", "root") }}
    - group: {{ keytab.get("group", "root") }}

{%- for identity in keytab.get("identities", []) %}
freeipa_keytab_{{ keytab_file }}_{{ identity.service }}_{{ identity.get('host', ipa_host) }}:
  cmd.run:
    - name: "kinit -kt /etc/krb5.keytab host/{{ ipa_host }} && ipa-getkeytab -k {{ keytab_file }} -s {{ client.server }} -p {{ identity.service }}/{{ identity.get('host', ipa_host) }}; E=$?; kdestroy; exit $E"
    - unless: "kinit -kt {{ keytab_file }} {{ identity.service }}/{{ identity.get('host', ipa_host) }}; E=$?; /usr/bin/kdestroy; exit $E"
    - env:
      - KRB5CCNAME: /tmp/krb5cc_salt
    - require:
      - cmd: freeipa_client_install
    - require_in:
      - file: freeipa_keytab_{{ keytab_file }}
{%- endfor %}

{%- endfor %}

{%- endif %}
