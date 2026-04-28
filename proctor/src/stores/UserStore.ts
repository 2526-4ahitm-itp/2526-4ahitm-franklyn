import {defineStore, storeToRefs} from "pinia";
import {useThemeStore} from "@/stores/ThemeStore.ts";
import {useApolloClientStore} from "@/stores/ApolloClientStore.ts";
import {gql} from "@apollo/client";

export const useUserStore = defineStore("userStore", async () => {
  const {client} = useApolloClientStore()
  const {theme} = storeToRefs(useThemeStore())

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
      return res.data.userInfo;
    }

  }
})
