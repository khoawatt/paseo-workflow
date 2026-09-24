def unique_preserving_order:
  reduce .[] as $item ([]; if index($item) == null then . + [$item] else . end);

def provider_family($provider):
  if ($provider | startswith("codex")) then "codex"
  elif ($provider | startswith("opencode")) then "opencode"
  else $provider
  end;

def model_catalog($provider):
  if provider_family($provider) == "codex" then ($codex_models[0].models // [])
  elif provider_family($provider) == "opencode" then ($opencode_models[0].models // [])
  else []
  end;

def supports_preferences($provider; $model; $thinking):
  if $model == null then
    $thinking == null
  else
    ([model_catalog($provider)[] | select(.id == $model)] | first) as $entry
    | ($entry != null)
      and (
        $thinking == null
        or (($entry.thinkingOptions // []) | map(.id) | index($thinking) != null)
      )
  end;

def implementation_provider($profiles):
  ([ $profiles[]
     | select(.id == "design-agent-implementation-v02")
     | .provider ] | first) // null;

def ordered_candidates($policy; $existing; $profiles):
  ($policy.allowedProviders // []) as $allowed
  | if $policy.id == "design-agent-review-v02" then
      implementation_provider($profiles) as $implementation
      | ([ $allowed[] | select(. != $implementation) ]
         + [ $allowed[] | select(. == $implementation) ])
    elif $policy.id == "design-agent-specialist-v02"
         and (($existing.provider // null) as $provider | $allowed | index($provider) != null) then
      ([ $existing.provider ] + $allowed) | unique_preserving_order
    else
      $allowed
    end;

def choose_provider($policy; $existing; $profiles):
  ordered_candidates($policy; $existing; $profiles)
  | [ .[]
      | select(supports_preferences(.; $existing.model // null; $existing.thinkingOptionId // null)) ]
  | first;

def canonical_profile($policy; $existing; $provider):
  ($existing // {}) as $old
  | ($policy.defaultModeByProvider[$provider] // null) as $default_mode
  | ($old + {
      id: $policy.id,
      name: $policy.name,
      provider: $provider,
      notes: $policy.notes
    })
  | if ($old | length) == 0 then
      if $default_mode == null then . else . + {modeId: $default_mode} end
    elif ($old.modeId // null) == null
         or provider_family($old.provider // "") != provider_family($provider) then
      if $default_mode == null then del(.modeId) else . + {modeId: $default_mode} end
    else
      .
    end;

def reconcile_profiles($existing_profiles; $profile_policy):
  reduce $profile_policy.profiles[] as $policy (
    {profiles: $existing_profiles, blockers: []};
    (.profiles | map(.id) | index($policy.id)) as $index
    | (if $index == null then {} else .profiles[$index] end) as $existing
    | choose_provider($policy; $existing; .profiles) as $provider
    | if $provider == null then
        .blockers += [{
          profileId: $policy.id,
          model: ($existing.model // null),
          thinkingOptionId: ($existing.thinkingOptionId // null)
        }]
      else
        canonical_profile($policy; $existing; $provider) as $profile
        | if $index == null then
            .profiles += [$profile]
          else
            .profiles[$index] = $profile
          end
      end
  );

def reconcile_providers($config; $provider_policy):
  reduce ($provider_policy | to_entries[]) as $entry (
    $config;
    .agents.providers = (.agents.providers // {})
    | .agents.providers[$entry.key] = (
        (.agents.providers[$entry.key] // {}) + $entry.value
      )
    | if $entry.key == "codex-lead" then
        .agents.providers[$entry.key] |= del(.paseoTools)
      else
        .
      end
  );

($input_config[0] // {})
| .["$schema"] = "https://paseo.sh/schemas/paseo.config.v1.json"
| .version = 1
| .daemon = (.daemon // {})
| .daemon.mcp = ((.daemon.mcp // {}) + {
    enabled: true,
    injectIntoAgents: true
  })
| reconcile_providers(.; $provider_policy[0]) as $provider_config
| reconcile_profiles(
    ($provider_config.daemon.agentProfiles // []);
    $profiles_policy[0]
  ) as $profile_result
| {
    config: ($provider_config
      | .daemon.agentProfiles = $profile_result.profiles),
    blockers: $profile_result.blockers
  }
