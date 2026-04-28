import {defineStore, storeToRefs} from "pinia";
import {useThemeStore} from "@/stores/ThemeStore.ts";
import {useApolloClientStore} from "@/stores/ApolloClientStore.ts";
import {gql} from "@apollo/client";

export const useUserStore = defineStore("userStore", () => {
  const {client} = useApolloClientStore()
  const {theme} = storeToRefs(useThemeStore())
  let isInit = false

  let preferredUsername = "";
  let givenName = "";
  let familyName = "";
  let email = "";

  async function init() {
    if (isInit) return;
    await userInfo();
    isInit = true
  }


  async function updateSettings(input: { language: string }) {
    const res = await client.mutate<{ updateSettings: User }>({
      mutation: gql`
        mutation UpdateSettings($userSettings: UpdateSettingsInput!) {
          updateSettings(settingsInput: $userSettings) {
            id
            language
            theme
          }
        }
      `,
      variables: {
        userSettings: {
          language: input.language,
          theme: theme
        },

      },
    })

    if (res.data?.updateSettings) {
      return res.data.updateSettings
    }

  }

  async function userInfo() {
    const res = await client.query({
      query: gql`
        query UserInfo {
          userInfo {
            id
            preferred_username
            email
            given_name
            family_name
          }
        }
      `,
    })
    if(res.data?.userInfo) {
      email = res.data.userInfo.email;
      preferredUsername = res.data.userInfo.preferred_username;
      givenName = res.data.userInfo.given_name;
      familyName = res.data.userInfo.family_name;


      return res.data.userInfo;
    }

  }
  return {updateSettings, userInfo, init, email, preferredUsername, givenName, familyName}
})
