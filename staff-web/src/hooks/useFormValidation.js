import { useCallback, useState } from 'react'

/**
 * Form validation hook.
 *
 * @param {object} initialValues - Initial form field values.
 * @param {function} validate - Validation function that receives values and returns an errors object.
 */
export function useFormValidation(initialValues, validate) {
  const [values, setValues] = useState(initialValues)
  const [errors, setErrors] = useState({})
  const [touched, setTouched] = useState({})

  const handleChange = useCallback((e) => {
    const { name, value } = e.target
    setValues((prev) => ({ ...prev, [name]: value }))
    // Clear error for this field when user types
    if (errors[name]) {
      setErrors((prev) => ({ ...prev, [name]: undefined }))
    }
  }, [errors])

  const handleBlur = useCallback((e) => {
    const { name } = e.target
    setTouched((prev) => ({ ...prev, [name]: true }))
  }, [])

  const setValue = useCallback((name, value) => {
    setValues((prev) => ({ ...prev, [name]: value }))
    if (errors[name]) {
      setErrors((prev) => ({ ...prev, [name]: undefined }))
    }
  }, [errors])

  const setFieldError = useCallback((name, message) => {
    setErrors((prev) => ({ ...prev, [name]: message }))
  }, [])

  const setFieldErrors = useCallback((errorsObj) => {
    setErrors((prev) => ({ ...prev, ...errorsObj }))
  }, [])

  const runValidation = useCallback(() => {
    if (!validate) return true
    const { isValid, errors: validationErrors } = validate(values)
    setErrors(validationErrors)
    return isValid
  }, [validate, values])

  const reset = useCallback(() => {
    setValues(initialValues)
    setErrors({})
    setTouched({})
  }, [initialValues])

  return {
    values,
    errors,
    touched,
    handleChange,
    handleBlur,
    setValue,
    setFieldError,
    setFieldErrors,
    runValidation,
    reset,
    setValues,
  }
}
