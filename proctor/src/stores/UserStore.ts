import {defineStore, storeToRefs} from "pinia";
import {useThemeStore} from "@/stores/ThemeStore.ts";
import {useApolloClientStore} from "@/stores/ApolloClientStore.ts";
import {gql} from "@apollo/client";
import type {User} from "@/types/User.ts";
import {ref} from "vue";

export const useUserStore = defineStore("userStore", () => {
  const {client} = useApolloClientStore()
  const {theme} = storeToRefs(useThemeStore())
  let isInit = false

  const preferredUsername = ref<string>();
  const givenName = ref<string>();
  const familyName = ref<string>();
  const email = ref<string>();
  const language = ref<string>()



  async function init() {
    if (isInit) return;
    await userInfo();
    isInit = true
  }


  async function updateSettings(language: string ) {
    console.warn(theme.value.toUpperCase())
    const res = await client.mutate<{ updateSettings: User }>({
      mutation: gql`
        mutation UpdateSettings($userSettings: UpdateUserSettingsInput!) {
          updateSettings(settingsInput: $userSettings) {
            id
            language
            theme
          }
        }
      `,
      variables: {
        userSettings: {
          language: language,
          theme: theme.value.toUpperCase()
        },

      },
    })

    if (res.data?.updateSettings) {
      return res.data.updateSettings
    }

  }

  async function userInfo() {
    const res = await client.query<{ userInfo : User}>({
      query: gql`
        query UserInfo {
          userInfo {
            id
            preferredUsername
            email
            givenName
            familyName
            language
            theme
          }
        }
      `,
    })
    if(res.data?.userInfo) {
      email.value = res.data.userInfo.email;
      preferredUsername.value = res.data.userInfo.preferredUsername;
      givenName.value = res.data.userInfo.givenName;
      familyName.value = res.data.userInfo.familyName;
      language.value = res.data.userInfo.language;



      return res.data.userInfo;
    }

  }
  return {updateSettings, userInfo, init, email, preferredUsername, givenName, familyName}
})
