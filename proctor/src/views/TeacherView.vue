<script lang="ts">
import { useQuery } from '@vue/apollo-composable'
import gql from 'graphql-tag'

export default {
  setup () {
    const { result } = useQuery(gql`
      query getTeachers {
        teachers {
          id
          name
        }
      }
    `)
    return {
      result
    }
  },
}
</script>

